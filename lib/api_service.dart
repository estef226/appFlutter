import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://10.0.2.2:3000";

  Future<void> addUsuario(String nombre, String rol) async {
    print("📝 Iniciando addUsuario - Nombre: $nombre, Rol: $rol");
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/usuarios'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'nombre': nombre,
          'rol': rol,
        }),
      );

      print("🔍 Respuesta del servidor: ${response.statusCode} - ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Usuario agregado exitosamente");
      } else {
        print("❌ Error al agregar usuario: [${response.statusCode}] ${response.body}");
        throw Exception('Error al agregar usuario: ${response.body}');
      }
    } catch (e) {
      print("💥 Error en addUsuario: $e");
      throw Exception('Error en la operación: $e');
    }
  }

  Future<List<Usuario>> fetchUsuarios() async {
    print("🔄 Iniciando fetchUsuarios");
    final url = Uri.parse("$baseUrl/usuarios");
    try {
      print("📡 Realizando petición GET a: $url");
      final response = await http.get(url);
      print("📥 Respuesta recibida: [${response.statusCode}]");
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        print("📊 Usuarios obtenidos: ${data.length}");
        return data.map((json) => Usuario.fromJson(json)).toList();
      } else {
        print("⚠️ Error en fetchUsuarios: [${response.statusCode}] ${response.body}");
        throw Exception("Error en la API: ${response.body}");
      }
    } catch (e) {
      print("💥 Error en fetchUsuarios: $e");
      throw Exception("Error en la conexión: $e");
    }
  }

  Future<void> updateUsuario(String id, String nombre, String rol) async {
    print("🔄 Iniciando updateUsuario - ID: $id, Nombre: $nombre, Rol: $rol");
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/usuarios/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'nombre': nombre,
          'rol': rol,
        }),
      );

      print("📡 Respuesta de actualización: [${response.statusCode}] ${response.body}");

      if (response.statusCode != 200 && response.statusCode != 201) {
        print("❌ Error en la actualización: ${response.body}");
        throw Exception(json.decode(response.body)['error'] ?? 'Error al actualizar usuario');
      }
      print("✅ Usuario actualizado correctamente");
    } catch (e) {
      print("💥 Error en updateUsuario: $e");
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  Future<void> deleteUsuario(String id) async {
    print("🗑️ Iniciando deleteUsuario - ID: $id");
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/usuarios/$id'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("📡 Respuesta de eliminación: [${response.statusCode}] ${response.body}");

      if (response.statusCode != 200) {
        print("❌ Error en la eliminación: ${response.body}");
        throw Exception(json.decode(response.body)['error'] ?? 'Error al eliminar usuario');
      }
      print("✅ Usuario eliminado correctamente");
    } catch (e) {
      print("💥 Error en deleteUsuario: $e");
      throw Exception('Error al eliminar usuario: $e');
    }
  }
}

class Usuario {
  final String id;
  final String nombre;
  final String rol;

  Usuario({required this.id, required this.nombre, required this.rol});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? 'Sin nombre',
      rol: json['rol'] ?? 'Sin rol',
    );
  }
}

