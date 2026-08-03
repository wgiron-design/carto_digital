import '../models/capa_geometrica.dart';

/// Resultado sellado para la selección unificada de geometrías en el mapa.
sealed class ResultadoSeleccion {}

/// Seleccionado un punto/estructura.
class PuntoSeleccionado extends ResultadoSeleccion {
  final PuntoEstructura punto;
  PuntoSeleccionado(this.punto);
}

/// Seleccionada una línea/camino.
class LineaSeleccionada extends ResultadoSeleccion {
  final LineaCamino linea;
  LineaSeleccionada(this.linea);
}

/// Seleccionado un polígono/UPM.
class PoligonoSeleccionado extends ResultadoSeleccion {
  final PoligonoUPM poligono;
  PoligonoSeleccionado(this.poligono);
}

/// Sin entidad encontrada en el radio de tolerancia.
class SinResultado extends ResultadoSeleccion {}
