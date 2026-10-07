package com.example.cyclecore_app

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

/**
 * La app corre en un motor de Flutter que vive en el proceso, no en la
 * pantalla.
 *
 * Con el motor por defecto, cerrar la app desde "recientes" (o salir con
 * atrás en Android viejos) destruía la Activity y con ella el motor: el
 * código Dart se detenía y la grabación se cortaba aunque el servicio de
 * ubicación en primer plano siguiera vivo. Con el motor guardado en
 * [FlutterEngineCache], la Activity puede morir y volver a nacer
 * (tocando la notificación "CycleCore está grabando tu ruta") y se
 * engancha al mismo motor: la salida sigue grabándose sin cortes.
 */
class MainActivity : FlutterActivity() {
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        return cache.get(ENGINE_ID)
            ?: FlutterEngine(context.applicationContext).also { cache.put(ENGINE_ID, it) }
    }

    /** El motor no se destruye con la pantalla: es lo que mantiene viva la grabación. */
    override fun shouldDestroyEngineWithHost(): Boolean = false

    companion object {
        const val ENGINE_ID = "cyclecore"
    }
}
