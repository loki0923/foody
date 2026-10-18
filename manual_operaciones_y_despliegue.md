# MANUAL DE DESPLIEGUE, OPERACIÓN Y CONCILIACIÓN: FOODY VENEZUELA

Este manual contiene las instrucciones técnicas y operativas para llevar la plataforma **Foody Venezuela** a producción, conectar la base de datos persistente en **Supabase**, desplegar en **Vercel** y operar el modelo comercial de comisiones del **3.00%**.

---

## 1. CONFIGURACIÓN DE BASE DE DATOS EN SUPABASE

### 1.1 Creación del Proyecto
1. Inicie sesión en [supabase.com](https://supabase.com).
2. Cree una nueva organización o seleccione una existente.
3. Cree un nuevo proyecto:
   - **Name**: `foody-venezuela`
   - **Database Password**: Genere una contraseña segura y guárdela en su gestor de credenciales.
   - **Region**: Seleccione `us-east-1 (N. Virginia)` o `sa-east-1 (São Paulo)` para menor latencia desde Venezuela.
   - **Pricing Plan**: Free Tier ($0/mes para pruebas) o Pro ($25/mes para producción comercial).

### 1.2 Ejecución de Migraciones y Esquema DDL
1. En el panel de Supabase, ingrese al módulo **SQL Editor** (icono `>_`).
2. Abra el archivo local [`supabase/migrations/20261018000001_initial_schema.sql`](file:///c:/Users/Windows%2011/OneDrive/Desktop/proyecto/supabase/migrations/20261018000001_initial_schema.sql).
3. Pegue el contenido completo y presione **Run**.
   - Esto creará los tipos ENUM, las 24 tablas relacionales, índices y las políticas de aislamiento **Row Level Security (RLS)**.
4. Luego, abra el archivo local [`supabase/migrations/20261018000002_seed_data.sql`](file:///c:/Users/Windows%2011/OneDrive/Desktop/proyecto/supabase/migrations/20261018000002_seed_data.sql), pegue su contenido y ejecute **Run**.
   - Esto registrará la regla de comisión oficial del 3.00%, categorías gastronómicas y restaurantes de prueba identificados como `[DEMO]`.

### 1.3 Obtención de Claves de Conexión
1. Vaya a **Project Settings** > **API**.
2. Copie:
   - **Project URL** (`https://xxxxxxxxxxxx.supabase.co`)
   - **Project API Anon Key** (`eyJh...`)
   - **Project API Service Role Key** (manténgala en secreto, solo para variables del servidor).

---

## 2. VARIABLES DE ENTORNO

Configure el archivo `.env.local` (o configure en el panel de Vercel):

```bash
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://su-proyecto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=su-anon-key-publica
SUPABASE_SERVICE_ROLE_KEY=su-service-role-key-privada

# Dominio y URL Base
NEXT_PUBLIC_APP_URL=https://foody.com.ve

# Parámetros Comerciales Foody Venezuela
NEXT_PUBLIC_BRAND_NAME=Foody
NEXT_PUBLIC_BRAND_SLOGAN="El sabor de Venezuela a un mensaje de distancia"
NEXT_PUBLIC_DEFAULT_COMMISSION_PCT=3.00
NEXT_PUBLIC_DEFAULT_CURRENCY=USD
NEXT_PUBLIC_SECONDARY_CURRENCY=VES
```

---

## 3. DESPLIEGUE EN VERCEL

1. Suba el código a su repositorio Git (GitHub o GitLab).
2. Ingrese a [vercel.com](https://vercel.com) y seleccione **Add New Project**.
3. Importe el repositorio `proyecto`.
4. En **Framework Preset**, Vercel detectará automáticamente **Next.js**.
5. Despliegue la sección **Environment Variables** y agregue las variables descritas arriba.
6. Haga clic en **Deploy**.
7. En **Settings > Domains**, vincule su dominio personalizado (ej. `foody.com.ve` o `app.foody.ve`). Los certificados SSL/HTTPS se renovarán automáticamente.

---

## 4. PROCEDIMIENTO OPERATIVO CON RESTAURANTES REALES

### 4.1 Onboarding del Primer Restaurante Real
1. Inserte el restaurante en la tabla `businesses` con:
   - `name`: Nombre comercial del local.
   - `slug`: URL amigable (ej. `arepera-el-trogon`).
   - `phone_whatsapp`: Número en formato E.164 (ej. `+584121234567`).
   - `is_active`: `true`.
2. Configure sus métodos de pago aceptados en `business_payment_methods` (Pago Móvil con número de cuenta, banco, cédula/RIF).
3. Inserte sus zonas de delivery y tarifas en `delivery_zones`.
4. Cargue sus productos y categorías en `products` y `categories`.

### 4.2 Recepción y Despacho de Pedidos
1. El restaurante mantiene abierta la pantalla de su panel:
   `https://foody.com.ve/panel` en su teléfono, tablet o computadora en cocina.
2. Cuando un cliente genera un pedido, el sistema crea la orden en estado `created` y abre WhatsApp con el formato:
   `🍔 PEDIDO OFICIAL #FDY-XXXX | Foody Venezuela...`
3. Al recibir el mensaje por WhatsApp:
   - El personal presiona **"1. Reconocer Mensaje WhatsApp"** en su panel.
   - Valida stock y presiona **"2. Aceptar Pedido en Cocina"**. En este instante se congela la regla de comisión (3.00%).
   - Al salir el repartidor, presiona **"3. Enviar con Repartidor"**.
   - Al completarse la entrega y cobro, presiona **"4. Confirmar Entrega y Cobro"**.
   - **Efecto Contable**: El sistema inscribe de forma inmutable un asiento en `commission_ledger` con estado `confirmed`.

### 4.3 Conciliación Quincenal y Liquidación de Comisiones
1. El día 15 y último de cada mes, la administración ingresa a:
   `https://foody.com.ve/admin` > pestaña **Estados de Cuenta**.
2. Selecciona el comercio y revisa el `merchant_statement`:
   - Total de pedidos concretados.
   - Monto total de ventas de comida.
   - Comisión acumulada del 3.00%.
   - Saldo deudor pendiente.
3. Se envía el estado de cuenta en formato digital al WhatsApp o correo del restaurante.
4. El restaurante paga la comisión por Pago Móvil o transferencia a la cuenta de la plataforma Foody.
5. El administrador hace clic en **"Registrar Pago de Comisión Recibido"**, ingresa la referencia bancaria del Pago Móvil y confirma.
   - El sistema registra la entrada `merchant_payment` con importe negativo, saldando el estado de cuenta (`settled`).

### 4.4 Tratamiento de Disputas y Cancelaciones
- Si un restaurante cancela una orden, el sistema exige seleccionar el motivo (`Cliente no respondió`, `Sin stock`, etc.).
- Las órdenes canceladas **no generan comisión**.
- Si hubo un error humano o devolución de comida tras haberse marcado como completada:
  - El administrador no borra la fila histórica.
  - Pulsa **"Ajustar"** en el Libro Mayor (`/admin`), registra el monto en negativo (ej. `-$0.35`) y documenta el motivo y responsable.

### 4.5 Auditoría de Fugas Comerciales (Detección de Anomalías)
- La pestaña **Auditoría y Fugas WhatsApp** en `/admin` calcula el ratio de pedidos creados vs completados vs cancelados.
- Si un restaurante reporta una tasa de cancelación superior al 35% de los pedidos que abrieron WhatsApp, se le asigna bandera roja (**Riesgo Alto**) para auditoría mediante llamada telefónica o compra misteriosa.
