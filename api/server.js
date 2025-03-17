require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const os = require('os'); // Para obtener la IP local

const app = express();
app.use(express.json());
app.use(require('cors')());

const PORT = 3000;
const MONGO_URI = "mongodb://localhost:27017/fullstack_game"; // Asegúrate de que MongoDB esté corriendo

// Conectar a MongoDB
mongoose.connect(MONGO_URI, { 
    useNewUrlParser: true, 
    useUnifiedTopology: true
}).then(() => console.log("✅ Conectado a MongoDB"))
  .catch(err => console.error("❌ Error al conectar:", err));

// Modelo de Usuario actualizado
const Usuario = mongoose.model("Usuario", new mongoose.Schema({
    nombre: { type: String, required: true },
    rol: { type: String, required: true },
    email: { type: String },
    fechaCreacion: { type: Date, default: Date.now },
    activo: { type: Boolean, default: true }
}));

// Ruta GET para obtener los usuarios
app.get('/usuarios', async (req, res) => {
    console.log('📥 GET /usuarios - Solicitando lista de usuarios');
    try {
        const usuarios = await Usuario.find();
        console.log(`✅ Usuarios encontrados: ${usuarios.length}`);
        res.json(usuarios);
    } catch (error) {
        console.error('❌ Error en GET /usuarios:', error);
        res.status(500).json({ error: "Error al obtener los usuarios", detalles: error.message });
    }
});

// Nueva ruta para buscar por rol
app.get('/usuarios/rol/:rol', async (req, res) => {
    console.log(`🔍 Buscando usuarios con rol: ${req.params.rol}`);
    try {
        const usuarios = await Usuario.find({ rol: req.params.rol });
        res.json(usuarios);
    } catch (error) {
        console.error('❌ Error en búsqueda por rol:', error);
        res.status(500).json({ error: "Error en la búsqueda" });
    }
});

// Nueva ruta para estadísticas
app.get('/usuarios/stats', async (req, res) => {
    try {
        const totalUsuarios = await Usuario.countDocuments();
        const porRol = await Usuario.aggregate([
            { $group: { _id: "$rol", total: { $sum: 1 } } }
        ]);
        const activos = await Usuario.countDocuments({ activo: true });

        res.json({
            total: totalUsuarios,
            porRol: porRol,
            activos: activos
        });
    } catch (error) {
        console.error('❌ Error en estadísticas:', error);
        res.status(500).json({ error: "Error al obtener estadísticas" });
    }
});

// Ruta PUT actualizada
app.put('/usuarios/:id', async (req, res) => {
    const { id } = req.params;
    console.log(`📝 PUT /usuarios/${id} - Actualizando usuario`);
    console.log('📦 Datos recibidos:', req.body);
    
    try {
        const { nombre, rol } = req.body;

        if (!nombre || !rol) {
            console.log('⚠️ Datos incompletos');
            return res.status(400).json({ error: "Nombre y rol son obligatorios" });
        }

        const usuarioActualizado = await Usuario.findByIdAndUpdate(
            id,
            { nombre, rol },
            { new: true }
        );

        if (!usuarioActualizado) {
            console.log('⚠️ Usuario no encontrado');
            return res.status(404).json({ error: "Usuario no encontrado" });
        }

        console.log('✅ Usuario actualizado:', usuarioActualizado);
        res.json(usuarioActualizado);
    } catch (error) {
        console.error('❌ Error en PUT /usuarios:', error);
        res.status(500).json({ error: "Error al actualizar el usuario", detalles: error.message });
    }
});

// Ruta POST actualizada
app.post('/usuarios', async (req, res) => {
    console.log('📥 POST /usuarios - Creando nuevo usuario');
    console.log('📦 Datos recibidos:', req.body);
    
    try {
        const { nombre, rol } = req.body;

        if (!nombre || !rol) {
            console.log('⚠️ Datos incompletos');
            return res.status(400).json({ error: "Nombre y rol son obligatorios" });
        }

        const nuevoUsuario = new Usuario({ nombre, rol });
        await nuevoUsuario.save();
        console.log('✅ Usuario creado:', nuevoUsuario);
        res.status(201).json(nuevoUsuario);
    } catch (error) {
        console.error('❌ Error en POST /usuarios:', error);
        res.status(500).json({ error: "Error al registrar el usuario", detalles: error.message });
    }
});

// Ruta DELETE para eliminar un usuario por ID
app.delete('/usuarios/:id', async (req, res) => {
    const { id } = req.params;
    console.log(`🗑️ DELETE /usuarios/${id} - Eliminando usuario`);
    
    try {
        const usuarioEliminado = await Usuario.findByIdAndDelete(id);
        if (!usuarioEliminado) {
            console.log('⚠️ Usuario no encontrado');
            return res.status(404).json({ error: "Usuario no encontrado" });
        }
        console.log('✅ Usuario eliminado:', usuarioEliminado);
        res.json({ mensaje: "Usuario eliminado correctamente", usuarioEliminado });
    } catch (error) {
        console.error('❌ Error en DELETE /usuarios:', error);
        res.status(500).json({ error: "Error al eliminar el usuario", detalles: error.message });
    }
});

// Iniciar servidor
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor corriendo en:`);
    console.log(`   👉 Local: http://localhost:${PORT}`);
});
