FROM golang:1.22-alpine AS builder

WORKDIR /app/src
COPY src/ ./

# Initialize module and build
RUN go mod init hivemind-app && \
    CGO_ENABLED=0 GOOS=linux go build -o /app/hivemind-app .

FROM alpine:3.19

WORKDIR /app
COPY --from=builder /app/hivemind-app .

EXPOSE 8080
RUN adduser -D -u 1000 appuser
USER appuser

ENTRYPOINT ["./hivemind-app"]