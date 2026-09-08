package br.com.imobagent.api;

import java.time.Instant;
import java.util.Map;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestControllerAdvice
class ApiExceptionHandler {
  @ExceptionHandler(org.springframework.dao.EmptyResultDataAccessException.class)
  @ResponseStatus(HttpStatus.NOT_FOUND)
  Map<String, Object> notFound() { return Map.of("erro", "Recurso nao encontrado", "timestamp", Instant.now().toString()); }
  @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
  @ResponseStatus(HttpStatus.CONFLICT)
  Map<String, Object> conflict() { return Map.of("erro", "Dados conflitam com um registro existente", "timestamp", Instant.now().toString()); }
}
