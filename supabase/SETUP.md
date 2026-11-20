# Configurar acceso docente

La aplicación puede seguir funcionando en modo local. Para habilitar cuentas Google y permisos por curso:

1. Crea un proyecto de Supabase. Abre el archivo `supabase/schema.sql` en los archivos del repositorio, copia todo su contenido y pégalo en una consulta nueva del **SQL Editor** de Supabase. Ejecuta esa consulta; no escribas la ruta `supabase/schema.sql` dentro del editor.
2. En [Google Auth Platform](https://console.cloud.google.com/auth/overview), selecciona o crea un proyecto. Configura **Branding** y **Audience**; para cuentas Google personales, elige **External**. Mientras la app esté en modo **Testing**, agrega las cuentas docentes como test users. En **Data Access**, asegúrate de incluir `openid`, `.../auth/userinfo.email` y `.../auth/userinfo.profile`.
3. En Google Auth Platform > **Clients**, crea un cliente OAuth de tipo **Web application**. En **Authorized JavaScript origins**, agrega el origen publicado de Mi curso (por ejemplo, `https://mi-sitio.netlify.app`, sin ruta). En **Authorized redirect URIs**, pega exactamente el callback que muestra Supabase en **Authentication > Providers > Google** (tiene el formato `https://<project-ref>.supabase.co/auth/v1/callback`). Guarda el **Client ID** y el **Client Secret**.
4. En Supabase > **Authentication > Providers > Google**, habilita Google e ingresa el Client ID y Client Secret. En **Authentication > URL Configuration**, configura como **Site URL** el sitio publicado y agrega como redirect permitido la URL exacta de la app, incluyendo `/mi-curso.html` si ese es el archivo que abre Mi curso. No uses `file://`.
5. En **Project Settings > Data API**, copia el **Project URL**. En **Project Settings > API Keys**, copia la clave **Publishable** (o `anon` si aparece la vista Legacy). Pega ambos valores en `supabase-config.js`. No uses la clave **Secret**/`service_role` ni compartas el Client Secret.
6. Agrega el correo Google del administrador en el SQL Editor:

   ```sql
   insert into public.app_admins (email)
   values (lower('TU_CORREO_GOOGLE'))
   on conflict (email) do nothing;
   ```

7. Publica el sitio y entra con esa cuenta. Importa una copia JSON exportada desde la aplicación local. Luego asigna cada docente a los cursos necesarios como **Solo lectura** o **Puede editar**.

Los docentes pueden autenticarse con Google, pero no reciben cursos hasta que un administrador los asigne. Las políticas RLS de Supabase controlan lecturas y escrituras en el servidor; ocultar un curso en la interfaz no es una medida de seguridad.

Antes de habilitar datos reales, probá con cuentas separadas: una cuenta sin asignación no debe ver cursos; una cuenta **Solo lectura** debe poder ver pero no guardar; una cuenta **Puede editar** debe poder guardar; y solo el administrador debe poder asignar accesos, importar o eliminar cursos.

## Instalar Mi curso como aplicación

La página `mi-curso.html` se puede instalar desde un navegador compatible cuando se sirve por HTTPS. En Android/Chrome, abrí el menú del navegador y elegí **Instalar aplicación** o **Agregar a pantalla principal**. En iPhone/iPad, abrila en Safari, tocá **Compartir** y luego **Agregar a pantalla de inicio**. En una computadora, Chrome o Edge ofrece **Instalar Mi curso** desde el menú o el ícono de instalación de la barra de direcciones.

La PWA conserva la misma interfaz y abre en una ventana independiente. Guarda en caché solo la carcasa de la aplicación para poder abrirla; iniciar sesión y sincronizar cursos requiere conexión a Internet. Los JSON de alumnos no se guardan en la caché offline.

## Migración

- Antes de importar, descarga una copia JSON desde la aplicación actual y guárdala en un lugar privado.
- La importación agrega cursos nuevos y no reemplaza cursos que ya existan en Supabase.
- Verifica cursos, cantidad de alumnos y notas antes de entregar accesos.
- Los JSON de cursos que ya están en este repositorio se mantienen; según lo indicado, su publicación está autorizada por los alumnos. Para cualquier nueva copia de datos, conserva esa autorización antes de compartirla. La clave `anon` está diseñada para el navegador, pero solo es segura con RLS activo; la `service_role` nunca debe aparecer en el sitio.
