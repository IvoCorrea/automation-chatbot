package br.com.imobagent.api;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

/** Protege a API chamada pelo n8n. Em desenvolvimento, token vazio permite testes locais. */
@Component
class InternalTokenFilter extends OncePerRequestFilter {
  private final String token;
  InternalTokenFilter(@Value("${app.internal-token}") String token) { this.token = token; }

  @Override protected boolean shouldNotFilter(HttpServletRequest request) {
    return token.isBlank() || request.getRequestURI().startsWith("/actuator/");
  }
  @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    if (!token.equals(request.getHeader("X-Internal-Token"))) {
      response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Token interno ausente ou invalido");
      return;
    }
    chain.doFilter(request, response);
  }
}
