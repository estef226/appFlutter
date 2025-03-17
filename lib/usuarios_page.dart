import 'package:flutter/material.dart';
import 'api_service.dart';

class UsuariosPage extends StatefulWidget {
  @override
  _UsuariosPageState createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  String? _currentUserId;

  late Future<List<Usuario>> _usuarios;
  final ApiService apiService = ApiService();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController rolController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarUsuarios();
  }

  void _cargarUsuarios() {
    setState(() {
      _usuarios = apiService.fetchUsuarios();
    });
  }

  void _agregarUsuario() async {
    if (_formKey.currentState!.validate()) {
      print("📝 Validación exitosa del formulario");
      try {
        await apiService.addUsuario(nombreController.text, rolController.text);
        _mostrarMensaje("✅ Usuario agregado correctamente");
        _limpiarFormulario();
        _cargarUsuarios();
      } catch (e) {
        _mostrarMensaje("❌ Error: ${e.toString()}");
      }
    }
  }

  void _actualizarUsuario(String id) async {
    if (_formKey.currentState!.validate()) {
      try {
        await apiService.updateUsuario(id, nombreController.text, rolController.text);
        _mostrarMensaje("Usuario actualizado correctamente");
        _limpiarFormulario();
        _cargarUsuarios();
      } catch (e) {
        _mostrarMensaje("Error: ${e.toString()}");
      }
    }
  }

  void _eliminarUsuario(String id) async {
    try {
      await apiService.deleteUsuario(id);
      _mostrarMensaje("Usuario eliminado correctamente");
      _cargarUsuarios();
    } catch (e) {
      _mostrarMensaje("Error: ${e.toString()}");
    }
  }

  void _prepararEdicion(Usuario usuario) {
    setState(() {
      _isEditing = true;
      _currentUserId = usuario.id;
      nombreController.text = usuario.nombre;
      rolController.text = usuario.rol;
    });
  }

  void _limpiarFormulario() {
    setState(() {
      _isEditing = false;
      _currentUserId = null;
      nombreController.clear();
      rolController.clear();
    });
    _formKey.currentState?.reset();
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarFormularioUsuario([Usuario? usuario]) {
    final esEdicion = usuario != null;
    
    // Crear nuevos controladores temporales para no modificar los originales inmediatamente
    final tempNombreController = TextEditingController();
    final tempRolController = TextEditingController();
    
    // Crear una clave de formulario local para este diálogo
    final localFormKey = GlobalKey<FormState>();
    
    if (esEdicion) {
      tempNombreController.text = usuario.nombre;
      tempRolController.text = usuario.rol;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(esEdicion ? 'Editar Usuario' : 'Nuevo Usuario'),
          content: Form(
            key: localFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: tempNombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    icon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un nombre';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: tempRolController,
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    icon: Icon(Icons.work),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingrese un rol';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (localFormKey.currentState!.validate()) {
                  try {
                    if (esEdicion) {
                      await apiService.updateUsuario(
                        usuario.id, 
                        tempNombreController.text, 
                        tempRolController.text
                      );
                      _mostrarMensaje("Usuario actualizado correctamente");
                    } else {
                      await apiService.addUsuario(
                        tempNombreController.text, 
                        tempRolController.text
                      );
                      _mostrarMensaje("✅ Usuario agregado correctamente");
                    }
                    
                    // Solo actualizamos los controladores principales si la operación fue exitosa
                    nombreController.text = tempNombreController.text;
                    rolController.text = tempRolController.text;
                    
                    _limpiarFormulario();
                    _cargarUsuarios();
                    Navigator.pop(context);
                  } catch (e) {
                    _mostrarMensaje("❌ Error: ${e.toString()}");
                  }
                }
              },
              child: Text(esEdicion ? 'Actualizar' : 'Agregar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión de Usuarios'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarUsuarios,
          ),
        ],
      ),
      body: FutureBuilder<List<Usuario>>(
        future: _usuarios,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay usuarios'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                var usuario = snapshot.data![index];
                return Card(
                  child: ListTile(
                    title: Text(usuario.nombre),
                    subtitle: Text('Rol: ${usuario.rol}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _mostrarFormularioUsuario(usuario),  // Aquí usamos el modal para editar
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmarEliminacion(usuario),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioUsuario(), // Aquí usamos el modal para agregar
        child: Icon(Icons.add),
        tooltip: 'Agregar Usuario',
      ),
    );
  }

  void _confirmarEliminacion(Usuario usuario) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text('¿Estás seguro de eliminar a ${usuario.nombre}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                _eliminarUsuario(usuario.id);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }
}
