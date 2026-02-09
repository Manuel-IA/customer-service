# Customer Service (Rails 8.1 / Ruby 3.4)

Microservicio responsable de gestionar clientes y su `orders_count`.
Escucha eventos `order.created` desde RabbitMQ para incrementar el contador de pedidos por cliente.

## Stack
- Ruby 3.4.x
- Rails 8.1.x
- PostgreSQL 16
- RabbitMQ 3 (management)

---

## Requisitos
- Docker + Docker Compose (v2)

El repositorio levanta su propia DB + RabbitMQ + API + Consumer.

---

## Arquitectura y flujo

### Responsabilidad
- **API (customer-web):** CRUD/consulta de clientes (para esta prueba, lectura por id).
- **Consumer (customer-consumer):** procesa eventos `order.created` y actualiza `orders_count`.
- **Idempotencia:** se registra `event_id` en `ProcessedEvent` para evitar aplicar el mismo evento más de una vez.

### Flujo event-driven
```
order-service (publish order.created) -> RabbitMQ (exchange/orders) -> customer-consumer -> increment orders_count
```

### Decisiones de diseño (patrones / SOLID)
- **SRP (Single Responsibility):** el consumer/use case `Customers::OnOrderCreated` encapsula la lógica del evento; el controller solo expone HTTP.
- **Idempotencia como policy:** `ProcessedEvent` representa la política para no duplicar side-effects.
- **Separación de infraestructura:** RabbitMQ y DB viven fuera de la lógica de dominio; el consumer solo consume el payload y aplica el cambio.

---


## Red compartida (para comunicación entre repositorios)
Como `order-service` vive en otro repositorio, ambos servicios se comunican usando una red Docker externa compartida.

Crear una sola vez:

```bash
docker network create monokera-shared
```

---

## Ejecutar el servicio (Docker)

### Build + Up
```bash
docker compose up --build
```

### Servicios expuestos
- API (customer-web): http://localhost:3001
- PostgreSQL: localhost:5433
- RabbitMQ UI: http://localhost:15672

Credenciales RabbitMQ:
- user: `app`
- pass: `app`

---

## Endpoints

### Obtener cliente por id
```bash
curl -i http://localhost:3001/api/v1/customers/1
```

Ejemplo de respuesta:
```json
{
  "id": 1,
  "customer_name": "Ana Gómez",
  "address": "Cra 7 # 32-16, Bogotá",
  "orders_count": 3
}
```

---

## Eventos (RabbitMQ)

### Evento consumido
- exchange: `orders`
- routing_key: `order.created`

Payload mínimo esperado (ejemplo):
```json
{
  "event_id": "uuid",
  "event_type": "order.created",
  "occurred_at": "2026-02-09T00:00:00Z",
  "order": { "id": 10, "customer_id": 1 }
}
```

El consumer aplica idempotencia por `event_id` usando `ProcessedEvent`.

---

## Testing Strategy

- **Request specs (API)**: validan contrato HTTP del servicio de clientes (status codes y JSON response).
  - Ejemplos: `GET /api/v1/customers/:id` (200/404).
- **Unit specs (use cases)**: validan la lógica del consumidor de eventos de forma aislada.
  - Ejemplo: `Customers::OnOrderCreated` incrementa `orders_count` y es idempotente por `event_id`.
- **Idempotencia y concurrencia**: el use case crea/consulta `ProcessedEvent` y previene incrementos duplicados.
  - Se prueba re-ejecutando el mismo payload y verificando que el contador no crece.

Comando para ejecutar las pruebas:

```
rspec spec/
```

---
