<?php
//Begin Really Simple SSL session cookie settings
@ini_set('session.cookie_httponly', true);
@ini_set('session.cookie_secure', true);
@ini_set('session.use_only_cookies', true);
//END Really Simple SSL cookie settings

/**
 * Основные параметры WordPress.
 *
 * Скрипт для создания wp-config.php использует этот файл в процессе установки.
 * Необязательно использовать веб-интерфейс, можно скопировать файл в "wp-config.php"
 * и заполнить значения вручную.
 *
 * Этот файл содержит следующие параметры:
 *
 * * Настройки MySQL
 * * Секретные ключи
 * * Префикс таблиц базы данных
 * * ABSPATH
 *
 * @link https://ru.wordpress.org/support/article/editing-wp-config-php/
 *
 * @package WordPress
 */

// ** Параметры базы данных: Эту информацию можно получить у вашего хостинг-провайдера ** //
/** Имя базы данных для WordPress */
// Prefer environment variables (Railway/Render), fallback to provided Railway PUBLIC proxy as defaults
$env_db_name = getenv('MYSQLDATABASE') ?: getenv('MYSQL_DATABASE') ?: getenv('DB_NAME') ?: 'railway';
$env_db_user = getenv('MYSQLUSER') ?: getenv('MYSQL_USER') ?: getenv('DB_USER') ?: 'root';
$env_db_pass = getenv('MYSQLPASSWORD') ?: getenv('MYSQL_PASSWORD') ?: getenv('DB_PASSWORD') ?: '';
$env_db_host = getenv('MYSQLHOST') ?: getenv('MYSQL_HOST') ?: 'localhost';
$env_db_port = getenv('MYSQLPORT') ?: getenv('MYSQL_PORT') ?: '3306'; // Prefer safe local defaults for public repos

define( 'DB_NAME', $env_db_name );

/** Имя пользователя базы данных */
define( 'DB_USER', $env_db_user );

/** Пароль к базе данных */
define( 'DB_PASSWORD', $env_db_pass );

/** Имя сервера базы данных (можно указать host:port) */
define( 'DB_HOST', $env_db_host . ':' . $env_db_port );

/** Кодировка базы данных для создания таблиц. */
define( 'DB_CHARSET', 'utf8mb4' );

/** Схема сопоставления. Не меняйте, если не уверены. */
define( 'DB_COLLATE', '' );

/**#@+
 * Уникальные ключи и соли для аутентификации.
 *
 * Смените значение каждой константы на уникальную фразу. Можно сгенерировать их с помощью
 * {@link https://api.wordpress.org/secret-key/1.1/salt/ сервиса ключей на WordPress.org}.
 *
 * Можно изменить их, чтобы сделать существующие файлы cookies недействительными.
 * Пользователям потребуется авторизоваться снова.
 *
 * @since 2.6.0
 */
define( 'AUTH_KEY',         '@,Su24UD@n]/)UY7VuR7%er|?.GFhgGSNHAV+XTGq>h<+.UODh.Zgz]Y8sU(j%Xf' );
define( 'SECURE_AUTH_KEY',  'n/CxP6*uO2ZSh/x5PwI|k=Nci:Y~, O k0,dqEg~MUs&q=SpTK2(}Z0P>.+`V7 s' );
define( 'LOGGED_IN_KEY',    'X(ddwG(tNmeWR2Jx:)E /^u>KV,6fU/ej;RTf)|i`Z=W.]_*YFK%&QpmX)8FxD9/' );
define( 'NONCE_KEY',        'Z;]Ws_fABZ:>8j[qQ)j:lT9Z/{Y([=DnKukk_[o<HNL4T{0lH24eL4sGIce[-_/Z' );
define( 'AUTH_SALT',        'lqS+us[Ci?00Osg<?g)UkeG!$;>9sn?yD!+]X-)dfqb<r_,|Se+E?PbWs/|b2`)<' );
define( 'SECURE_AUTH_SALT', 'NoHg[~/2peowJH7EcXr|Zmp:-ftVo`@O?5~ls.:cAYD5hN5+-d|k;DZ1d9W]oXQf' );
define( 'LOGGED_IN_SALT',   'mT=J#|1$CC-Dn!^r_nF TLt>Iou-SmxlX%AKZl@2IGrehgaE6#Bx.NrQ;=pl_mLS' );
define( 'NONCE_SALT',       'lfSM1w[J]hn;r)WXu:H&z/^c=Yztbe:(t+TvEkQ,ky{*2!GoTu@18dXun;),eu?~' );

/**#@-*/

/**
 * Префикс таблиц в базе данных WordPress.
 *
 * Можно установить несколько сайтов в одну базу данных, если использовать
 * разные префиксы. Пожалуйста, указывайте только цифры, буквы и знак подчеркивания.
 */
$table_prefix = 'hihqh_';

/**
 * Для разработчиков: Режим отладки WordPress.
 *
 * Измените это значение на true, чтобы включить отображение уведомлений при разработке.
 * Разработчикам плагинов и тем настоятельно рекомендуется использовать WP_DEBUG
 * в своём рабочем окружении.
 *
 * Информацию о других отладочных константах можно найти в документации.
 *
 * @link https://ru.wordpress.org/support/article/debugging-in-wordpress/
 */
define( 'WP_DEBUG', false );

/* Произвольные значения добавляйте между этой строкой и надписью "дальше не редактируем". */



/* Это всё, дальше не редактируем. Успехов! */

/** Абсолютный путь к директории WordPress. */
if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', __DIR__ . '/' );
}

/** Инициализирует переменные WordPress и подключает файлы. */
require_once ABSPATH . 'wp-settings.php';
