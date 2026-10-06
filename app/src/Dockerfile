FROM golang:1.22-alpine AS builder

WORKDIR /app

COPY go.mod ./

RUN go mod download

COPY . .

# Compile a static, lightweight binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /app/hivemind-app .

FROM alpine:3.19

# Install CA certificates for outbound HTTPS support & security scanning compliance
RUN apk --no-cache add ca-certificates

WORKDIR /app

# Copy binary from builder
COPY --from=builder /app/hivemind-app .

# Default fallback tag (overridden at runtime by Kubernetes/Helm via env vars)
ENV HELLO_TAG=latest

# Expose internal port
EXPOSE 8080

# Run as non-root user for security best practices
RUN adduser -D -u 1000 appuser

USER appuser

ENTRYPOINT ["./hivemind-app"]