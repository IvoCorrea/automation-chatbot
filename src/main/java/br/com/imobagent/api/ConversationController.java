package br.com.imobagent.api;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import java.util.*;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/conversas")
class ConversationController {
  private final NamedParameterJdbcTemplate db;
  ConversationController(NamedParameterJdbcTemplate db) { this.db = db; }

  @GetMapping("/{id}/mensagens")
  List<Map<String,Object>> messages(@PathVariable UUID id) {
    return db.queryForList("SELECT id,conversa_id,papel,conteudo,timestamp,tokens,provider_message_id FROM mensagens WHERE conversa_id=:id ORDER BY timestamp", Map.of("id", id));
  }

  @PostMapping("/{id}/mensagens")
  Map<String,Object> addMessage(@PathVariable UUID id, @Valid @RequestBody MessageInput input) {
    Map<String,Object> p = new HashMap<>(); p.put("id",id); p.put("papel",input.papel()); p.put("conteudo",input.conteudo()); p.put("tokens",input.tokens()); p.put("provider",input.providerMessageId());
    List<Map<String,Object>> rows = db.queryForList("""
      INSERT INTO mensagens (conversa_id,papel,conteudo,tokens,provider_message_id)
      VALUES (:id,CAST(:papel AS mensagem_papel),:conteudo,:tokens,:provider)
      ON CONFLICT (provider_message_id) WHERE provider_message_id IS NOT NULL DO NOTHING
      RETURNING id,conversa_id,papel,conteudo,timestamp,tokens,provider_message_id""", p);
    if (!rows.isEmpty()) return rows.getFirst();
    return db.queryForMap("SELECT id,conversa_id,papel,conteudo,timestamp,tokens,provider_message_id FROM mensagens WHERE provider_message_id=:provider", p);
  }

  @PostMapping("/{id}/handoff")
  Map<String,Object> requestHandoff(@PathVariable UUID id) {
    Map<String,Object> conversation = db.queryForMap("UPDATE conversas SET status_handoff='solicitado' WHERE id=:id RETURNING id,lead_id,status_handoff", Map.of("id", id));
    db.update("UPDATE leads SET status='handoff' WHERE id=:leadId", Map.of("leadId", conversation.get("lead_id")));
    return conversation;
  }

  record MessageInput(@NotBlank String papel, @NotBlank String conteudo, Integer tokens, String providerMessageId) {}
}
