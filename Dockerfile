FROM oven/bun:1-alpine AS frontend-builder

WORKDIR /app/frontend

COPY frontend/package.json frontend/pnpm-lock.yaml* ./

RUN bun install --frozen-lockfile

COPY frontend/ ./

RUN bun run build

FROM golang:1.24-alpine AS backend-builder

WORKDIR /app

COPY backend/go.mod backend/go.sum ./

RUN go mod download

COPY backend/ ./

RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-w -s" -o main .

FROM alpine:latest

WORKDIR /app

RUN apk --no-cache add ca-certificates

COPY --from=backend-builder /app/main .

COPY --from=frontend-builder /app/frontend/dist ./frontend/dist

COPY backend/floppa ./floppa
COPY backend/macky ./macky

#COPY backend/config.json ./config.json

EXPOSE 8080

CMD ["./main"]
