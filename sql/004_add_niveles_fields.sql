-- =============================================================================
-- Script 004: Campos de Descripción, Auditoría y Constraints para Niveles
-- =============================================================================

ALTER TABLE niveles
    ADD COLUMN IF NOT EXISTS descripcion  VARCHAR(50)   NULL,
    ADD COLUMN IF NOT EXISTS created_by   UUID          REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_by   UUID          REFERENCES users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS sync_version INTEGER       NOT NULL DEFAULT 0;

-- Asegura que no existan números duplicados de nivel dentro de la misma estructura
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'uq_niveles_estructura_numero'
    ) THEN
        ALTER TABLE niveles ADD CONSTRAINT uq_niveles_estructura_numero UNIQUE (estructura_id, numero);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_niveles_estructura_id ON niveles (estructura_id);
CREATE INDEX IF NOT EXISTS idx_niveles_updated_at    ON niveles (updated_at);
