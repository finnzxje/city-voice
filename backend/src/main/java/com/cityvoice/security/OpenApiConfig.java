package com.cityvoice.security;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.enums.SecuritySchemeType;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityScheme;
import org.springframework.context.annotation.Configuration;

@Configuration
@OpenAPIDefinition(info = @Info(title = "CityVoice API", version = "1.0.0", description = "REST API documentation for the CityVoice Civic Issue Reporting Platform"), security = @SecurityRequirement(name = "bearerAuth"))
@SecurityScheme(name = "bearerAuth", type = SecuritySchemeType.HTTP, scheme = "bearer", bearerFormat = "JWT", description = "Enter your JWT token here (without the 'Bearer ' prefix). You can get a token by using the /api/auth/staff/login or /api/auth/citizen/login endpoints.")
public class OpenApiConfig {
}
