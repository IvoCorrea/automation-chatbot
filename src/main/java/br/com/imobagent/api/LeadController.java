package br.com.imobagent.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import java.util.*;
import org.springframework.jdbc.core.namedparam.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api")
class LeadController {
  private final NamedParameterJdbcTemplate db;
  LeadController(NamedParameterJdbcTemplate db) { this.db = db; }

  @PostMapping("/leads")
  Map<String,Object> upsertLead(@Valid @RequestBody LeadInput input) {
    Map<String,Object> params = new HashMap<>();
    params.put("telefone", input.telefone()); params.put("nome", input.nome()); params.put("origem", input.origem() == null ? "whatsapp" : input.origem()); params.put("metadados", input.metadados() == null ? "{}" : input.metadados());
    return one("""
      INSERT INTO leads (telefone,nome,origem,metadados) VALUES (:telefone,:nome,CAST(:origem AS lead_origem),CAST(:metadados AS jsonb))
      ON CONFLICT (telefone) DO UPDATE SET nome=COALESCE(EXCLUDED.nome,leads.nome), metadados=leads.metadados || EXCLUDED.metadados
      RETURNING id,telefone,nome,status,origem,criado_em,atualizado_em""", params);
  }

  @GetMapping("/leads/{id}") Map<String,Object> lead(@PathVariable UUID id) {
    return one("SELECT id,telefone,nome,status,origem,metadados,criado_em,atualizado_em FROM leads WHERE id=:id", Map.of("id",id));
  }

  @PostMapping("/leads/{leadId}/conversas") Map<String,Object> openConversation(@PathVariable UUID leadId) {
    return one("""
      INSERT INTO conversas (lead_id) VALUES (:leadId)
      ON CONFLICT (lead_id) WHERE encerrada_em IS NULL DO UPDATE SET lead_id=EXCLUDED.lead_id
      RETURNING id,lead_id,iniciada_em,encerrada_em,status_handoff,chatwoot_conversation_id""", Map.of("leadId",leadId));
  }

  @PostMapping("/leads/{leadId}/qualificacoes") Map<String,Object> qualify(@PathVariable UUID leadId, @Valid @RequestBody QualificationInput q) {
    Map<String,Object> p = new HashMap<>(); p.put("leadId",leadId); p.put("finalidade",q.finalidade()); p.put("min",q.faixaPrecoMin()); p.put("max",q.faixaPrecoMax()); p.put("regiao",q.regiao()); p.put("urgencia",q.urgencia()); p.put("financiamento",q.precisaFinanciamento()); p.put("score",q.score());
    Map<String,Object> result = one("""
      INSERT INTO qualificacoes (lead_id,finalidade,faixa_preco_min,faixa_preco_max,regiao,urgencia,precisa_financiamento,score)
      VALUES (:leadId,CAST(:finalidade AS finalidade_tipo),:min,:max,:regiao,CAST(:urgencia AS urgencia_tipo),:financiamento,:score)
      RETURNING id,lead_id,finalidade,faixa_preco_min,faixa_preco_max,regiao,urgencia,precisa_financiamento,score,qualificado_em""", p);
    db.update("UPDATE leads SET status='qualificado' WHERE id=:id", Map.of("id",leadId));
    return result;
  }

  private Map<String,Object> one(String sql, Map<String,?> params) { return db.queryForMap(sql, params); }
  record LeadInput(@NotBlank @Pattern(regexp="^[0-9]{10,15}$") String telefone, String nome, String origem, String metadados) {}
  record QualificationInput(@NotBlank String finalidade, java.math.BigDecimal faixaPrecoMin, java.math.BigDecimal faixaPrecoMax, String regiao, String urgencia, Boolean precisaFinanciamento, Integer score) {}
}
