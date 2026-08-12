-- =============================================================================
-- Script 006: Documentación / Estructura esperada de tablas Catálogo
-- Tablas: cat_estructuras_categoria, cat_estructuras_tipo
-- =============================================================================

-- Tabla de tipos de estructura (ej: 1=Formal, 2=Referencia)
CREATE TABLE IF NOT EXISTS cat_estructuras_tipo (
    id   SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT
);

-- Tabla de categorías de estructura.
-- La columna `tipo` (INTEGER) referencia cat_estructuras_tipo.id:
--   tipo = 1  → categoría pertenece al tipo "Formal"
--   tipo = 2  → categoría pertenece al tipo "Referencia"
-- Esto permite el combo dependiente: al seleccionar un tipo en el formulario,
-- se filtra esta tabla WHERE tipo = $1 para poblar el combo de categoría.
CREATE TABLE IF NOT EXISTS cat_estructuras_categoria (
    id      SERIAL PRIMARY KEY,
    nombre  VARCHAR(100) NOT NULL,
    tipo    INTEGER NOT NULL REFERENCES cat_estructuras_tipo(id),
    descripcion TEXT
);
