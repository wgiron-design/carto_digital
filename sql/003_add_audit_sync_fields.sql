-- =============================================================================
-- Script 003: Agregar campos de Auditoría y Sincronización Offline
-- Tablas: estructuras, caminos, upms
-- Migración segura: ADD COLUMN IF NOT EXISTS (sin pérdida de datos)
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLA: estructuras
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE estructuras
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS device_id  VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS sync_version INTEGER NOT NULL DEFAULT 0;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLA: caminos
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE caminos
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS device_id  VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS sync_version INTEGER NOT NULL DEFAULT 0;

-- ─────────────────────────────────────────────────────────────────────────────
-- TABLA: upms
-- ─────────────────────────────────────────────────────────────────────────────
ALTER TABLE upms
    ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL,
    ADD COLUMN IF NOT EXISTS device_id  VARCHAR(100) NULL,
    ADD COLUMN IF NOT EXISTS sync_version INTEGER NOT NULL DEFAULT 0;

-- ─────────────────────────────────────────────────────────────────────────────
-- ÍNDICES para optimizar las consultas de sincronización
-- ─────────────────────────────────────────────────────────────────────────────

-- Índice para delta-sync: buscar registros modificados desde una fecha
CREATE INDEX IF NOT EXISTS idx_estructuras_updated_at ON estructuras (updated_at);
CREATE INDEX IF NOT EXISTS idx_caminos_updated_at     ON caminos     (updated_at);
CREATE INDEX IF NOT EXISTS idx_upms_updated_at        ON upms        (updated_at);

-- Índice para soft-delete: filtrar registros activos
CREATE INDEX IF NOT EXISTS idx_estructuras_deleted_at ON estructuras (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_caminos_deleted_at     ON caminos     (deleted_at) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_upms_deleted_at        ON upms        (deleted_at) WHERE deleted_at IS NULL;
