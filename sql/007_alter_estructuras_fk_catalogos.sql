-- =============================================================================
-- Script 007: Refactorización de columnas en "estructuras" (PostgreSQL / PostGIS)
-- Elimina: categoria, tipo_formal, tipo_referencia
-- Agrega: id_categoria, id_tipo (NOT NULL con FKs a las tablas catálogo)
-- =============================================================================

-- 1. Agregar nuevas columnas como NULL temporales para migración de datos
ALTER TABLE estructuras
    ADD COLUMN IF NOT EXISTS id_categoria INTEGER NULL,
    ADD COLUMN IF NOT EXISTS id_tipo      INTEGER NULL;

-- 2. Migrar datos existentes mapeando cadenas de texto a los IDs del catálogo por nombre
-- 2.1 Mapear id_categoria
UPDATE estructuras
SET id_categoria = c.id
FROM cat_estructuras_categoria c
WHERE estructuras.id_categoria IS NULL
  AND LOWER(TRIM(estructuras.categoria)) = LOWER(TRIM(c.nombre));

-- Si quedan categorías no coincidentes, fallback a primer id de categoría formal o por defecto (si aplica)
UPDATE estructuras
SET id_categoria = (SELECT id FROM cat_estructuras_categoria ORDER BY id ASC LIMIT 1)
WHERE id_categoria IS NULL;

-- 2.2 Mapear id_tipo desde tipo_formal o tipo_referencia
UPDATE estructuras
SET id_tipo = t.id
FROM cat_estructuras_tipo t
WHERE estructuras.id_tipo IS NULL
  AND (
    LOWER(TRIM(COALESCE(estructuras.tipo_formal, ''))) = LOWER(TRIM(t.nombre))
    OR LOWER(TRIM(COALESCE(estructuras.tipo_referencia, ''))) = LOWER(TRIM(t.nombre))
  );

-- Si quedan tipos no coincidentes, asignamos el primer tipo del catálogo asociado a la categoría asignada
UPDATE estructuras
SET id_tipo = (
    SELECT id FROM cat_estructuras_tipo 
    WHERE id_categoria = estructuras.id_categoria 
    ORDER BY id ASC LIMIT 1
)
WHERE id_tipo IS NULL;

-- En caso extremo de no encontrar tipo para esa categoría, asignar el primer tipo global
UPDATE estructuras
SET id_tipo = (SELECT id FROM cat_estructuras_tipo ORDER BY id ASC LIMIT 1)
WHERE id_tipo IS NULL;

-- 3. Aplicar restricción NOT NULL a las nuevas columnas
ALTER TABLE estructuras
    ALTER COLUMN id_categoria SET NOT NULL,
    ALTER COLUMN id_tipo SET NOT NULL;

-- 4. Agregar restricciones de Llave Foránea (Foreign Key)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_estructuras_cat_categoria'
    ) THEN
        ALTER TABLE estructuras 
            ADD CONSTRAINT fk_estructuras_cat_categoria 
            FOREIGN KEY (id_categoria) REFERENCES cat_estructuras_categoria(id);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_estructuras_cat_tipo'
    ) THEN
        ALTER TABLE estructuras 
            ADD CONSTRAINT fk_estructuras_cat_tipo 
            FOREIGN KEY (id_tipo) REFERENCES cat_estructuras_tipo(id);
    END IF;
END $$;

-- 5. Crear índices para optimizar los JOINs con catálogos
CREATE INDEX IF NOT EXISTS idx_estructuras_id_categoria ON estructuras (id_categoria);
CREATE INDEX IF NOT EXISTS idx_estructuras_id_tipo      ON estructuras (id_tipo);

-- 6. Eliminar columnas obsoletas
ALTER TABLE estructuras
    DROP COLUMN IF EXISTS categoria,
    DROP COLUMN IF EXISTS tipo_formal,
    DROP COLUMN IF EXISTS tipo_referencia;
