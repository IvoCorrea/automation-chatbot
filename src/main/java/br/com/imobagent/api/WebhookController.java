package br.com.imobagent.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.*;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

/** Entrada normalizada. O workflow n8n converte os payloads Meta/360dialog para este contrato. */
@RestController
@RequestMapping("/api/webhooks")
class WebhookController {
  private final NamedParameterJdbcTemplate db;
  WebhookController(NamedParameterJdbcTemplate db) { this.db = db; }
  @PostMapping("/whatsapp")
  Map<String,Object> receive(@Valid @RequestBody IncomingWhatsApp input) {
    Map<String,Object> p = new HashMap<>(); p.put("telefone",input.telefone()); p.put("nome",input.nome());
    Map<String,Object> lead = db.queryForMap("""
      INSERT INTO leads (telefone,nome) VALUES (:telefone,:nome)
      ON CONFLICT (telefone) DO UPDATE SET nome=COALESCE(EXCLUDED.nome,leads.nome) RETURNING id""", p);
    UUID leadId = (UUID) lead.get("id");
    Map<String,Object> conversation = db.queryForMap("""
      INSERT INTO conversas (lead_id) VALUES (:leadId)
      ON CONFLICT (lead_id) WHERE encerrada_em IS NULL DO UPDATE SET lead_id=EXCLUDED.lead_id RETURNING id""", Map.of("leadId",leadId));
    Map<String,Object> message = new HashMap<>(); message.put("conversationId",conversation.get("id")); message.put("content",input.conteudo()); message.put("providerId",input.providerMessageId());
    db.update("""
      INSERT INTO mensagens (conversa_id,papel,conteudo,provider_message_id) VALUES (:conversationId,'user',:content,:providerId)
      ON CONFLICT (provider_message_id) WHERE provider_message_id IS NOT NULL DO NOTHING""", message);
    return Map.of("leadId",leadId,"conversaId",conversation.get("id"),"aceita",true);
  }
  record IncomingWhatsApp(@NotBlank String telefone, String nome, @NotBlank String conteudo, String providerMessageId) {}
}
