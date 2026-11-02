/// Categorías de necesidades, estandarizadas con su ortografía correcta.
const List<String> categorias = [
  'Tecnología',
  'Mobiliario',
  'Útiles escolares',
  'Deportes',
  'Libros',
  'Infraestructura',
  'Alimentación',
  'Otro',
];

// Categorías que se guardaron antes (sin tildes) o escritas distinto.
const Map<String, String> _legacyCategorias = {
  'Tecnologia': 'Tecnología',
  'tecnologia': 'Tecnología',
  'Utiles escolares': 'Útiles escolares',
  'utiles escolares': 'Útiles escolares',
  'Alimentacion': 'Alimentación',
  'alimentacion': 'Alimentación',
};

/// Normaliza una categoría para mostrarla con tildes correctas,
/// aunque los datos viejos en Firestore estén sin ellas.
String normalizarCategoria(String raw) {
  return _legacyCategorias[raw] ?? raw;
}