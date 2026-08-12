-- =============================================================================
-- Script 005: Asegurar columna descripcion en la tabla locales y niveles
-- =============================================================================

ALTER TABLE niveles
    ADD COLUMN IF NOT EXISTS descripcion VARCHAR(50) NULL;

ALTER TABLE locales
    ADD COLUMN IF NOT EXISTS descripcion VARCHAR(150) NULL;
