package br.com.imobagent.api;

import java.math.BigDecimal;
import java.util.*;
import org.springframework.jdbc.core.namedparam.*;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/imoveis")
class PropertyController {
  private final NamedParameterJdbcTemplate db;
  PropertyController(NamedParameterJdbcTemplate db) { this.db = db; }

  @GetMapping
  List<Map<String,Object>> search(@RequestParam(required=false) String finalidade, @RequestParam(required=false) String bairro,
      @RequestParam(required=false) String cidade, @RequestParam(required=false) String tipo, @RequestParam(required=false) BigDecimal precoMin,
      @RequestParam(required=false) BigDecimal precoMax, @RequestParam(defaultValue="3") int limite) {
    StringBuilder sql = new StringBuilder("SELECT id,codigo,titulo,descricao,tipo,finalidade,preco,quartos,vagas,bairro,cidade FROM imoveis WHERE ativo=true");
    MapSqlParameterSource p = new MapSqlParameterSource();
    if (finalidade != null) { sql.append(" AND finalidade=CAST(:finalidade AS finalidade_tipo)"); p.addValue("finalidade",finalidade); }
    if (bairro != null) { sql.append(" AND bairro ILIKE '%' || :bairro || '%'"); p.addValue("bairro",bairro); }
    if (cidade != null) { sql.append(" AND cidade ILIKE '%' || :cidade || '%'"); p.addValue("cidade",cidade); }
    if (tipo != null) { sql.append(" AND tipo=CAST(:tipo AS imovel_tipo)"); p.addValue("tipo",tipo); }
    if (precoMin != null) { sql.append(" AND preco >= :precoMin"); p.addValue("precoMin",precoMin); }
    if (precoMax != null) { sql.append(" AND preco <= :precoMax"); p.addValue("precoMax",precoMax); }
    sql.append(" ORDER BY preco LIMIT :limite"); p.addValue("limite", Math.min(Math.max(limite, 1), 10));
    return db.queryForList(sql.toString(), p);
  }
}
