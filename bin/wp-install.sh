#!/usr/bin/env bash
# Complete the WordPress installation and seed demo content with WP-CLI.
# Runs INSIDE the wordpress container:  make install
#
# Idempotent: safe to run repeatedly. Existing content is left untouched.
#
# All demo content is fictional. Club, people, places, contact details and bank
# data are placeholders ("Musterstadt", "Max Mustermann", example.org, ...) and
# have to be replaced before a real site goes live.
set -euo pipefail

# Paths and the WP-CLI invocation are configurable so the same script can seed
# the Docker environment and a real server:
#   WP_PATH=/var/www/vhosts/example.com/httpdocs WORDPRESS_URL=https://example.com \
#     bash wp-install.sh
WP_PATH="${WP_PATH:-/var/www/html}"
# --allow-root is only accepted (and only needed) when actually running as root.
ALLOW_ROOT=""
[ "$(id -u)" = "0" ] && ALLOW_ROOT="--allow-root"
WP="wp $ALLOW_ROOT --path=$WP_PATH"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONTACT_EMAIL="${CONTACT_EMAIL:-info@example.org}"
URL="${WORDPRESS_URL:-http://localhost:${WORDPRESS_PORT:-8080}}"

echo "==> Waiting for the database"
for i in $(seq 1 30); do
  if $WP db check >/dev/null 2>&1; then break; fi
  sleep 2
done

if ! $WP core is-installed >/dev/null 2>&1; then
  echo "==> Installing WordPress at $URL"
  $WP core install \
    --url="$URL" \
    --title="${WORDPRESS_SITE_TITLE:-Lions Club Musterstadt}" \
    --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
    --locale="${WORDPRESS_LOCALE:-de_DE}" \
    --skip-email
else
  # Already installed (e.g. a blank installation on a server): keep its own URL.
  URL="$($WP option get home)"
  echo "==> WordPress already installed at $URL"
fi

echo "==> Language"
LOCALE="${WORDPRESS_LOCALE:-de_DE}"
if [ "$LOCALE" != "en_US" ]; then
  # Core translations supply the German month names used by the date format below.
  $WP language core install "$LOCALE" --activate >/dev/null 2>&1 || true
fi

echo "==> Activating theme"
$WP theme activate lions-theme
$WP option update blogname "${WORDPRESS_SITE_TITLE:-Lions Club Musterstadt}" >/dev/null
$WP option update blogdescription "Gemeinsam für unsere Gemeinschaft." >/dev/null
$WP rewrite structure '/%postname%/' >/dev/null
$WP option update timezone_string 'Europe/Berlin' >/dev/null
$WP option update date_format 'j. F Y' >/dev/null
$WP option update time_format 'H:i' >/dev/null

# ---------------------------------------------------------------------------
# --post_status=any: WordPress ships a *draft* "privacy-policy" page, and without
# it ensure_page would not find that page and would create a duplicate each run.
page_id() { $WP post list --post_type=page --post_status=any --name="$1" --field=ID --posts_per_page=1 | head -n1; }

# ensure_page <slug> <title> <parent-slug|""> <content>
ensure_page() {
  local slug="$1" title="$2" parent="$3" content="$4" id parent_id=0
  id=$(page_id "$slug")
  if [ -n "$id" ]; then echo "$id"; return; fi
  if [ -n "$parent" ]; then parent_id=$(page_id "$parent"); fi
  $WP post create --post_type=page --post_status=publish --post_name="$slug" --post_title="$title" \
    --post_parent="${parent_id:-0}" --post_content="$content" --porcelain
}

para() { printf '<!-- wp:paragraph -->\n<p>%s</p>\n<!-- /wp:paragraph -->\n' "$1"; }
heading() { printf '<!-- wp:heading -->\n<h2 class="wp-block-heading">%s</h2>\n<!-- /wp:heading -->\n' "$1"; }
# table <label> <value> [<label> <value> ...] -> a two-column core table block
table() {
  local rows=''
  while [ "$#" -ge 2 ]; do
    rows="$rows<tr><td>$1</td><td>$2</td></tr>"
    shift 2
  done
  printf '<!-- wp:table -->\n<figure class="wp-block-table"><table><tbody>%s</tbody></table></figure>\n<!-- /wp:table -->\n' "$rows"
}
# bullets <item> [<item> ...] -> a core list block
bullets() {
  local items=''
  for item in "$@"; do
    items="$items<!-- wp:list-item --><li>$item</li><!-- /wp:list-item -->"
  done
  printf '<!-- wp:list -->\n<ul class="wp-block-list">%s</ul>\n<!-- /wp:list -->\n' "$items"
}
# quote <text> <citation>
quote() {
  printf '<!-- wp:quote -->\n<blockquote class="wp-block-quote"><p>%s</p><cite>%s</cite></blockquote>\n<!-- /wp:quote -->\n' "$1" "$2"
}
heading3() { printf '<!-- wp:heading {"level":3} -->\n<h3 class="wp-block-heading">%s</h3>\n<!-- /wp:heading -->\n' "$1"; }
heading4() { printf '<!-- wp:heading {"level":4} -->\n<h4 class="wp-block-heading">%s</h4>\n<!-- /wp:heading -->\n' "$1"; }

echo "==> Removing WordPress sample content"
for slug in hello-world sample-page; do
  for id in $($WP post list --post_type=post,page --name="$slug" --field=ID); do $WP post delete "$id" --force >/dev/null; done
done
$WP comment delete 1 --force >/dev/null 2>&1 || true

echo "==> Pages"
HOME_ID=$(ensure_page home "Startseite" "" "$(para 'Siebzehn Mitglieder gründeten den Lions Club Musterstadt im Januar 1983. Seither hilft der Club dort, wo in Musterstadt und der Verbandsgemeinde Hilfe gebraucht wird — nach einem Leitsatz: We serve.')$(para 'Inklusions-Cup, Adventskalenderaktion und Benefizkonzerte finanzieren ganz Konkretes: Schulprojekte, Sportausrüstung und Unterstützung für Menschen mit Behinderung in der Region.')")
STORIES_ID=$(ensure_page stories "Aktuelles" "" "$(para 'News and stories from clubs around the world.')")
ensure_page our-history "Unsere Geschichte" "" "$(para 'Der Lions Club Musterstadt wurde am 11. Januar 1983 von siebzehn Gründungsmitgliedern aus Musterstadt und dem westlichen Umland ins Leben gerufen. Am 14. Mai 1983 folgte unter Gründungspräsident H. Mustermann die Charterfeier. Aus dieser kleinen Runde ist ein Club geworden, der seit über vier Jahrzehnten dort anpackt, wo in der Region Hilfe gebraucht wird.')$(heading 'Musterstadt am Fluss')$(para 'Musterstadt liegt am rechten Flussufer nördlich von Beispielstadt und markiert das Ende des Landschaftsschutzgebiets „Musterland“. Die Stadt ist Wallfahrtsort und Hochschulstandort zugleich: Hier finden sich ein Wallfahrtszentrum, eine kirchliche Hochschule und eine private Wirtschaftshochschule. Die Mitglieder des Clubs kommen aus ganz unterschiedlichen Berufen und bringen ihre jeweiligen Erfahrungen in die gemeinsame Arbeit ein.')$(heading 'Der Leitgedanke: We serve')$(para 'Wie alle Lions Clubs handelt auch Musterstadt nach dem Leitsatz „We serve“. Lions Clubs International zählt rund 1,4 Millionen Mitglieder weltweit, davon etwa 47.600 in über 1.400 deutschen Clubs. Im Mittelpunkt steht die Hilfe zur Selbsthilfe: Unterstützung soll Menschen in die Lage versetzen, ihren Weg weiterzugehen, statt dauerhafte Abhängigkeit zu schaffen. Dazu kommen kulturelle Projekte und das Eintreten für Völkerverständigung, Toleranz und Bildung.')$(quote 'Wir alle zusammen haben gezeigt, was We serve bedeutet.' 'Max Mustermann bei der Langen Tafel zum 25-jährigen Bestehen der Tafel Beispielstadt, Mai 2025')$(heading 'Was uns durch das Clubjahr begleitet')$(para 'Einige Aktivitäten sind über die Jahre zu festen Terminen geworden:')$(bullets \
  'Der <strong>Inklusions-Cup</strong>, ein inklusives Basketballturnier für gemischte Läufer- und Rollstuhlteams, findet seit dem 6. Mai 2006 jährlich in Beispielhausen statt.' \
  'Die <strong>Adventskalenderaktion</strong> verbindet 24 Gewinn-Törchen mit dem örtlichen Handel und finanziert einen Teil der Spendenprojekte.' \
  '<strong>Benefizkonzerte</strong> – zuletzt mit dem Landespolizeiorchester Musterland in der Pilgerkirche – bringen den größten Teil der jährlichen Erlöse zusammen.' \
  'Konzerte in der spätgotischen <strong>Klosterkirche auf der Insel Musterau</strong> und die Beteiligung am Musterstädter Weihnachtsmarkt gehören seit langem zum Clubjahr.')$(heading 'Meilensteine')$(table \
  '1983' 'Gründung am 11. Januar, Charterfeier am 14. Mai mit siebzehn Mitgliedern' \
  '2006' 'Erster Inklusions-Cup am 6. Mai in Beispielhausen' \
  '2024' 'Lesung aus der „Musterstädter Familien-Saga“ am 9. April in Musterstadt, begleitet von einer Schauspielerin' \
  '2024' 'Adventskalenderaktion mit 24 Gewinn-Törchen beim örtlichen Handel' \
  '2025' 'Benefizkonzert des Landespolizeiorchesters Musterland am 3. April in der Pilgerkirche' \
  '2025' 'Lange Tafel zum 25-jährigen Bestehen der Tafel Beispielstadt am 21. Mai auf dem Marktplatz' \
  '2025' 'Zwanzigster Inklusions-Cup mit mehr als sechzig Teilnehmenden' \
  '2025' 'Übergabe von 7.500 Euro an drei regionale Projekte am 2. Juli')$(heading 'Wohin die Spenden gegangen sind')$(para 'Was der Club sammelt, bleibt in der Region. Eine Auswahl aus den vergangenen Jahren:')$(bullets \
  '<strong>7.500 Euro</strong> aus dem Benefizkonzert 2025 für die Projekt Tierwelt, das Projekt Snoezelen und die Spielraum-Initiative der Hochschule Beispielstadt.' \
  '<strong>5.000 Euro</strong> für den Ausbau der Tierwelt der Förder- und Wohnstätten Musterland gGmbH in Musterdorf – gemeinsam mit den Lions Clubs Beispielstadt, Beispielstadt-Nord und Beispielstadt-Süd.' \
  '<strong>5.000 Euro</strong> für das ambulante Kinder- und Jugendhospiz Beispielstadt.' \
  '<strong>2.000 Euro</strong> für die Wasserrettung Musterstadt zur Teilnahme an einer Rettungsschwimm-Weltmeisterschaft.' \
  '<strong>1.000 Euro</strong> für ein Mitmach-Zirkusprojekt der Grundschule Musterdorf, an dem rund 45 Kinder aus Schule und Kindergarten teilnahmen.' \
  '<strong>1.000 Euro</strong> für den Bewegungsraum der Grundschule am Park in Beispielstadt.')$(heading 'Präsidentschaften')$(para 'Die Amtsübergabe findet traditionell im Sommer statt, zuletzt in der Gutsschänke in Beispieldorf.')$(table \
  '2023/2024' 'Anna Beispiel' \
  '2024/2025' 'Klaus Mustermann' \
  '2025/2026' 'Erika Musterfrau')$(para 'Den vollständigen Vorstand des laufenden Clubjahres finden Sie auf der Seite <a href="/leadership/">Vorstand</a>.')" >/dev/null
ensure_page leadership "Vorstand" "" "$(heading 'Der Lions Club Musterstadt Vorstand 2025/2026')$(table \
  'Präsidentin'           'Erika Musterfrau' \
  'Past-Präsident'        'Klaus Mustermann' \
  '1. Vizepräsident'      'Peter Beispiel' \
  '2. Vizepräsidentin'    'Sabine Beispiel' \
  'Sekretär'              'Thomas Muster' \
  'Schatzmeisterin'       'Petra Muster' \
  'Clubmaster'            'Anna Beispiel' \
  'Presse-Beauftragter'   'Michael Beispiel' \
  'Activity-Beauftragter' 'Peter Beispiel' \
  'Leos/Jugend'           'Julia Muster' \
  'Aufnahmeausschuss'     'Erika Musterfrau' \
  'Internet Beauftragter' 'Michael Beispiel' \
  'Lionsarchiv'           'Karl Mustermann' \
  'Rechnungsprüfer'       'Stefan Beispiel und Nina Muster')" >/dev/null
# "Mitmachen" and "Ehrenamt" are one page. The parent stays published because the
# child's permalink (and "Spenden") hang off it, but Lions\Theme\Functions\Redirects
# sends /get-involved/ to /get-involved/volunteer/, so there is only one page to edit.
ensure_page get-involved "Mitmachen" "" "$(para 'Diese Seite leitet auf <a href="/get-involved/volunteer/">Mitmachen</a> weiter.')" >/dev/null
ensure_page volunteer "Mitmachen" get-involved "$(para 'Der Lions Club Musterstadt lebt vom Engagement seiner Mitglieder. Ob als Mitglied, als Helferin oder Helfer bei einzelnen Aktionen oder als Förderin oder Förderer – es gibt viele Wege, sich einzubringen.')$(heading 'Was uns verbindet')$(para 'Unser Motto lautet „We serve“ – wir dienen. Seit 1983 setzen wir uns dort ein, wo in Musterstadt und der Verbandsgemeinde konkret geholfen werden muss: bei Schulprojekten, in der Jugendarbeit und für Menschen mit Behinderung.')$(heading 'So können Sie mitmachen')$(bullets \
  '<strong>Als Mitglied:</strong> Sie nehmen an unseren Clubabenden teil, bringen eigene Ideen ein und gestalten unsere Projekte mit.' \
  '<strong>Als Helferin oder Helfer:</strong> Sie unterstützen uns bei einzelnen Aktionen, etwa beim Benefizkonzert oder beim Adventskalender – ganz ohne Mitgliedschaft.' \
  '<strong>Als Förderin oder Förderer:</strong> Sie unterstützen unsere Projekte mit einer Spende an die Lions-Hilfe Musterstadt e. V.')$(heading 'Wer zu uns passt')$(para 'Sie brauchen keine besonderen Voraussetzungen – nur die Bereitschaft, Zeit und Erfahrung für andere einzusetzen. Wir freuen uns über Menschen aus allen Berufen und Lebensbereichen, die unsere Region ein Stück besser machen möchten.')$(heading 'Lernen Sie uns kennen')$(para 'Der beste erste Schritt ist ein persönliches Gespräch. Besuchen Sie uns unverbindlich als Gast an einem unserer Clubabende und lernen Sie den Club und unsere Projekte kennen.')$(para "Schreiben Sie uns einfach eine E-Mail an <a href=\"mailto:$CONTACT_EMAIL\">$CONTACT_EMAIL</a>. Wir melden uns zeitnah bei Ihnen und stimmen einen Termin ab.")" >/dev/null
ensure_page donate "Spenden" get-involved "$(para 'Der Lions Club Musterstadt hat für seine Spendenaktivitäten einen eigenen Verein gegründet, die <strong>Lions-Hilfe Musterstadt e. V.</strong>')$(table \
  'Verein'         'Lions-Hilfe Musterstadt e. V.' \
  'Sitz'           'Verbandsgemeinde Musterstadt' \
  'Vereinsregister' 'Nr. 0000')$(heading 'Spendenkonto')$(para 'Wenn Sie die Projekte des Lions Clubs Musterstadt unterstützen möchten, worum wir Sie herzlich bitten, können Sie dies mit einer Überweisung auf folgendes Konto tun:')$(table \
  'Kontoinhaber' 'Lions-Hilfe Musterstadt e. V.' \
  'IBAN'         'DE00 0000 0000 0000 0000 00' \
  'BIC'          'BEISPDE00XXX' \
  'Bank'         'Musterbank')$(para 'Wenn Sie eine Spendenquittung benötigen, vergessen Sie bitte nicht, Ihre Adresse anzugeben oder kontaktieren Sie unseren <a href="/contact/">Schatzmeister</a>.')$(para 'Vielen Dank für Ihre Hilfe!')" >/dev/null
ensure_page contact "Kontakt" "" "$(para 'Placeholder contact page. Add a contact form plugin or your preferred contact details here.')" >/dev/null
# Datenschutzerklärung. Sections that describe services this site does not use
# (OpenStreetMap, Chatwoot, Videokonferenzen, Calendly) are deliberately omitted.
DS="$(heading '1. Datenschutz auf einen Blick')"
DS="$DS$(heading3 'Allgemeine Hinweise')"
DS="$DS$(para 'Die folgenden Hinweise geben einen einfachen Überblick darüber, was mit Ihren personenbezogenen Daten passiert, wenn Sie diese Website besuchen. Personenbezogene Daten sind alle Daten, mit denen Sie persönlich identifiziert werden können. Ausführliche Informationen zum Thema Datenschutz entnehmen Sie unserer unter diesem Text aufgeführten Datenschutzerklärung.')"
DS="$DS$(heading3 'Datenerfassung auf dieser Website')"
DS="$DS$(heading4 'Wer ist verantwortlich für die Datenerfassung auf dieser Website?')"
DS="$DS$(para 'Die Datenverarbeitung auf dieser Website erfolgt durch den Websitebetreiber. Dessen Kontaktdaten können Sie dem Abschnitt „Hinweis zur verantwortlichen Stelle“ in dieser Datenschutzerklärung entnehmen.')"
DS="$DS$(heading4 'Wie erfassen wir Ihre Daten?')"
DS="$DS$(para 'Ihre Daten werden zum einen dadurch erhoben, dass Sie uns diese mitteilen. Hierbei kann es sich z. B. um Daten handeln, die Sie in ein Kontaktformular eingeben.')"
DS="$DS$(para 'Andere Daten werden automatisch oder nach Ihrer Einwilligung beim Besuch der Website durch unsere IT-Systeme erfasst. Das sind vor allem technische Daten (z. B. Internetbrowser, Betriebssystem oder Uhrzeit des Seitenaufrufs). Die Erfassung dieser Daten erfolgt automatisch, sobald Sie diese Website betreten.')"
DS="$DS$(heading4 'Wofür nutzen wir Ihre Daten?')"
DS="$DS$(para 'Ein Teil der Daten wird erhoben, um eine fehlerfreie Bereitstellung der Website zu gewährleisten. Andere Daten können zur Analyse Ihres Nutzerverhaltens verwendet werden.')"
DS="$DS$(heading4 'Welche Rechte haben Sie bezüglich Ihrer Daten?')"
DS="$DS$(para 'Sie haben jederzeit das Recht, unentgeltlich Auskunft über Herkunft, Empfänger und Zweck Ihrer gespeicherten personenbezogenen Daten zu erhalten. Sie haben außerdem ein Recht, die Berichtigung oder Löschung dieser Daten zu verlangen. Wenn Sie eine Einwilligung zur Datenverarbeitung erteilt haben, können Sie diese Einwilligung jederzeit für die Zukunft widerrufen. Außerdem haben Sie das Recht, unter bestimmten Umständen die Einschränkung der Verarbeitung Ihrer personenbezogenen Daten zu verlangen. Des Weiteren steht Ihnen ein Beschwerderecht bei der zuständigen Aufsichtsbehörde zu.')"
DS="$DS$(para 'Hierzu sowie zu weiteren Fragen zum Thema Datenschutz können Sie sich jederzeit an uns wenden.')"

DS="$DS$(heading '2. Hosting')"
DS="$DS$(para 'Wir hosten die Inhalte unserer Website bei folgendem Anbieter:')"
DS="$DS$(heading3 'Beispiel Hosting')"
DS="$DS$(para 'Anbieter ist die Beispiel Hosting GmbH, Musterstraße 2, 12345 Musterstadt (nachfolgend Hosting-Anbieter). Details entnehmen Sie der Datenschutzerklärung des Anbieters.')"
DS="$DS$(para 'Die Verwendung des Hosting-Anbieters erfolgt auf Grundlage von Art. 6 Abs. 1 lit. f DSGVO. Wir haben ein berechtigtes Interesse an einer möglichst zuverlässigen Darstellung unserer Website. Sofern eine entsprechende Einwilligung abgefragt wurde, erfolgt die Verarbeitung ausschließlich auf Grundlage von Art. 6 Abs. 1 lit. a DSGVO und § 25 Abs. 1 TTDSG, soweit die Einwilligung die Speicherung von Cookies oder den Zugriff auf Informationen im Endgerät des Nutzers im Sinne des TTDSG umfasst. Die Einwilligung ist jederzeit widerrufbar.')"
DS="$DS$(heading4 'Auftragsverarbeitung')"
DS="$DS$(para 'Wir haben einen Vertrag über Auftragsverarbeitung (AVV) zur Nutzung des oben genannten Dienstes geschlossen. Hierbei handelt es sich um einen datenschutzrechtlich vorgeschriebenen Vertrag, der gewährleistet, dass dieser die personenbezogenen Daten unserer Websitebesucher nur nach unseren Weisungen und unter Einhaltung der DSGVO verarbeitet.')"

DS="$DS$(heading '3. Allgemeine Hinweise und Pflichtinformationen')"
DS="$DS$(heading3 'Datenschutz')"
DS="$DS$(para 'Die Betreiber dieser Seiten nehmen den Schutz Ihrer persönlichen Daten sehr ernst. Wir behandeln Ihre personenbezogenen Daten vertraulich und entsprechend den gesetzlichen Datenschutzvorschriften sowie dieser Datenschutzerklärung.')"
DS="$DS$(para 'Wenn Sie diese Website benutzen, werden verschiedene personenbezogene Daten erhoben. Personenbezogene Daten sind Daten, mit denen Sie persönlich identifiziert werden können. Die vorliegende Datenschutzerklärung erläutert, welche Daten wir erheben und wofür wir sie nutzen. Sie erläutert auch, wie und zu welchem Zweck das geschieht.')"
DS="$DS$(para 'Wir weisen darauf hin, dass die Datenübertragung im Internet (z. B. bei der Kommunikation per E-Mail) Sicherheitslücken aufweisen kann. Ein lückenloser Schutz der Daten vor dem Zugriff durch Dritte ist nicht möglich.')"
DS="$DS$(heading3 'Hinweis zur verantwortlichen Stelle')"
DS="$DS$(para 'Die verantwortliche Stelle für die Datenverarbeitung auf dieser Website ist:')"
DS="$DS$(table \
  'Verein'  'Lions Club Musterstadt' \
  'Anschrift' 'Musterstraße 1, 12345 Musterstadt' \
  'Telefon' '+49 30 23125 100' \
  'E-Mail'  "$CONTACT_EMAIL")"
DS="$DS$(para 'Verantwortliche Stelle ist die natürliche oder juristische Person, die allein oder gemeinsam mit anderen über die Zwecke und Mittel der Verarbeitung von personenbezogenen Daten (z. B. Namen, E-Mail-Adressen o. Ä.) entscheidet.')"
DS="$DS$(heading3 'Speicherdauer')"
DS="$DS$(para 'Soweit innerhalb dieser Datenschutzerklärung keine speziellere Speicherdauer genannt wurde, verbleiben Ihre personenbezogenen Daten bei uns, bis der Zweck für die Datenverarbeitung entfällt. Wenn Sie ein berechtigtes Löschersuchen geltend machen oder eine Einwilligung zur Datenverarbeitung widerrufen, werden Ihre Daten gelöscht, sofern wir keine anderen rechtlich zulässigen Gründe für die Speicherung Ihrer personenbezogenen Daten haben (z. B. steuer- oder handelsrechtliche Aufbewahrungsfristen); im letztgenannten Fall erfolgt die Löschung nach Fortfall dieser Gründe.')"
DS="$DS$(heading3 'Allgemeine Hinweise zu den Rechtsgrundlagen der Datenverarbeitung auf dieser Website')"
DS="$DS$(para 'Sofern Sie in die Datenverarbeitung eingewilligt haben, verarbeiten wir Ihre personenbezogenen Daten auf Grundlage von Art. 6 Abs. 1 lit. a DSGVO bzw. Art. 9 Abs. 2 lit. a DSGVO, sofern besondere Datenkategorien nach Art. 9 Abs. 1 DSGVO verarbeitet werden. Im Falle einer ausdrücklichen Einwilligung in die Übertragung personenbezogener Daten in Drittstaaten erfolgt die Datenverarbeitung außerdem auf Grundlage von Art. 49 Abs. 1 lit. a DSGVO. Sofern Sie in die Speicherung von Cookies oder in den Zugriff auf Informationen in Ihr Endgerät eingewilligt haben, erfolgt die Datenverarbeitung zusätzlich auf Grundlage von § 25 Abs. 1 TTDSG. Die Einwilligung ist jederzeit widerrufbar. Sind Ihre Daten zur Vertragserfüllung oder zur Durchführung vorvertraglicher Maßnahmen erforderlich, verarbeiten wir Ihre Daten auf Grundlage des Art. 6 Abs. 1 lit. b DSGVO. Des Weiteren verarbeiten wir Ihre Daten, sofern diese zur Erfüllung einer rechtlichen Verpflichtung erforderlich sind, auf Grundlage von Art. 6 Abs. 1 lit. c DSGVO. Die Datenverarbeitung kann ferner auf Grundlage unseres berechtigten Interesses nach Art. 6 Abs. 1 lit. f DSGVO erfolgen. Über die jeweils im Einzelfall einschlägigen Rechtsgrundlagen wird in den folgenden Absätzen dieser Datenschutzerklärung informiert.')"
DS="$DS$(heading3 'Empfänger von personenbezogenen Daten')"
DS="$DS$(para 'Im Rahmen unserer Tätigkeit arbeiten wir mit verschiedenen externen Stellen zusammen. Dabei ist teilweise auch eine Übermittlung von personenbezogenen Daten an diese externen Stellen erforderlich. Wir geben personenbezogene Daten nur dann an externe Stellen weiter, wenn dies im Rahmen einer Vertragserfüllung erforderlich ist, wenn wir gesetzlich hierzu verpflichtet sind, wenn wir ein berechtigtes Interesse nach Art. 6 Abs. 1 lit. f DSGVO an der Weitergabe haben oder wenn eine sonstige Rechtsgrundlage die Datenweitergabe erlaubt. Beim Einsatz von Auftragsverarbeitern geben wir personenbezogene Daten nur auf Grundlage eines gültigen Vertrags über Auftragsverarbeitung weiter. Im Falle einer gemeinsamen Verarbeitung wird ein Vertrag über gemeinsame Verarbeitung geschlossen.')"
DS="$DS$(heading3 'Widerruf Ihrer Einwilligung zur Datenverarbeitung')"
DS="$DS$(para 'Viele Datenverarbeitungsvorgänge sind nur mit Ihrer ausdrücklichen Einwilligung möglich. Sie können eine bereits erteilte Einwilligung jederzeit widerrufen. Die Rechtmäßigkeit der bis zum Widerruf erfolgten Datenverarbeitung bleibt vom Widerruf unberührt.')"
DS="$DS$(heading3 'Widerspruchsrecht gegen die Datenerhebung in besonderen Fällen sowie gegen Direktwerbung (Art. 21 DSGVO)')"
DS="$DS$(para 'WENN DIE DATENVERARBEITUNG AUF GRUNDLAGE VON ART. 6 ABS. 1 LIT. E ODER F DSGVO ERFOLGT, HABEN SIE JEDERZEIT DAS RECHT, AUS GRÜNDEN, DIE SICH AUS IHRER BESONDEREN SITUATION ERGEBEN, GEGEN DIE VERARBEITUNG IHRER PERSONENBEZOGENEN DATEN WIDERSPRUCH EINZULEGEN; DIES GILT AUCH FÜR EIN AUF DIESE BESTIMMUNGEN GESTÜTZTES PROFILING. DIE JEWEILIGE RECHTSGRUNDLAGE, AUF DENEN EINE VERARBEITUNG BERUHT, ENTNEHMEN SIE DIESER DATENSCHUTZERKLÄRUNG. WENN SIE WIDERSPRUCH EINLEGEN, WERDEN WIR IHRE BETROFFENEN PERSONENBEZOGENEN DATEN NICHT MEHR VERARBEITEN, ES SEI DENN, WIR KÖNNEN ZWINGENDE SCHUTZWÜRDIGE GRÜNDE FÜR DIE VERARBEITUNG NACHWEISEN, DIE IHRE INTERESSEN, RECHTE UND FREIHEITEN ÜBERWIEGEN ODER DIE VERARBEITUNG DIENT DER GELTENDMACHUNG, AUSÜBUNG ODER VERTEIDIGUNG VON RECHTSANSPRÜCHEN (WIDERSPRUCH NACH ART. 21 ABS. 1 DSGVO).')"
DS="$DS$(para 'WERDEN IHRE PERSONENBEZOGENEN DATEN VERARBEITET, UM DIREKTWERBUNG ZU BETREIBEN, SO HABEN SIE DAS RECHT, JEDERZEIT WIDERSPRUCH GEGEN DIE VERARBEITUNG SIE BETREFFENDER PERSONENBEZOGENER DATEN ZUM ZWECKE DERARTIGER WERBUNG EINZULEGEN; DIES GILT AUCH FÜR DAS PROFILING, SOWEIT ES MIT SOLCHER DIREKTWERBUNG IN VERBINDUNG STEHT. WENN SIE WIDERSPRECHEN, WERDEN IHRE PERSONENBEZOGENEN DATEN ANSCHLIESSEND NICHT MEHR ZUM ZWECKE DER DIREKTWERBUNG VERWENDET (WIDERSPRUCH NACH ART. 21 ABS. 2 DSGVO).')"
DS="$DS$(heading3 'Beschwerderecht bei der zuständigen Aufsichtsbehörde')"
DS="$DS$(para 'Im Falle von Verstößen gegen die DSGVO steht den Betroffenen ein Beschwerderecht bei einer Aufsichtsbehörde zu, insbesondere in dem Mitgliedstaat ihres gewöhnlichen Aufenthalts, ihres Arbeitsplatzes oder des Orts des mutmaßlichen Verstoßes. Das Beschwerderecht besteht unbeschadet anderweitiger verwaltungsrechtlicher oder gerichtlicher Rechtsbehelfe.')"
DS="$DS$(heading3 'Recht auf Datenübertragbarkeit')"
DS="$DS$(para 'Sie haben das Recht, Daten, die wir auf Grundlage Ihrer Einwilligung oder in Erfüllung eines Vertrags automatisiert verarbeiten, an sich oder an einen Dritten in einem gängigen, maschinenlesbaren Format aushändigen zu lassen. Sofern Sie die direkte Übertragung der Daten an einen anderen Verantwortlichen verlangen, erfolgt dies nur, soweit es technisch machbar ist.')"
DS="$DS$(heading3 'Auskunft, Berichtigung und Löschung')"
DS="$DS$(para 'Sie haben im Rahmen der geltenden gesetzlichen Bestimmungen jederzeit das Recht auf unentgeltliche Auskunft über Ihre gespeicherten personenbezogenen Daten, deren Herkunft und Empfänger und den Zweck der Datenverarbeitung und ggf. ein Recht auf Berichtigung oder Löschung dieser Daten. Hierzu sowie zu weiteren Fragen zum Thema personenbezogene Daten können Sie sich jederzeit an uns wenden.')"
DS="$DS$(heading3 'Recht auf Einschränkung der Verarbeitung')"
DS="$DS$(para 'Sie haben das Recht, die Einschränkung der Verarbeitung Ihrer personenbezogenen Daten zu verlangen. Hierzu können Sie sich jederzeit an uns wenden. Das Recht auf Einschränkung der Verarbeitung besteht in folgenden Fällen:')"
DS="$DS$(bullets \
  'Wenn Sie die Richtigkeit Ihrer bei uns gespeicherten personenbezogenen Daten bestreiten, benötigen wir in der Regel Zeit, um dies zu überprüfen. Für die Dauer der Prüfung haben Sie das Recht, die Einschränkung der Verarbeitung Ihrer personenbezogenen Daten zu verlangen.' \
  'Wenn die Verarbeitung Ihrer personenbezogenen Daten unrechtmäßig geschah bzw. geschieht, können Sie statt der Löschung die Einschränkung der Datenverarbeitung verlangen.' \
  'Wenn wir Ihre personenbezogenen Daten nicht mehr benötigen, Sie sie jedoch zur Ausübung, Verteidigung oder Geltendmachung von Rechtsansprüchen benötigen, haben Sie das Recht, statt der Löschung die Einschränkung der Verarbeitung Ihrer personenbezogenen Daten zu verlangen.' \
  'Wenn Sie einen Widerspruch nach Art. 21 Abs. 1 DSGVO eingelegt haben, muss eine Abwägung zwischen Ihren und unseren Interessen vorgenommen werden. Solange noch nicht feststeht, wessen Interessen überwiegen, haben Sie das Recht, die Einschränkung der Verarbeitung Ihrer personenbezogenen Daten zu verlangen.')"
DS="$DS$(para 'Wenn Sie die Verarbeitung Ihrer personenbezogenen Daten eingeschränkt haben, dürfen diese Daten – von ihrer Speicherung abgesehen – nur mit Ihrer Einwilligung oder zur Geltendmachung, Ausübung oder Verteidigung von Rechtsansprüchen oder zum Schutz der Rechte einer anderen natürlichen oder juristischen Person oder aus Gründen eines wichtigen öffentlichen Interesses der Europäischen Union oder eines Mitgliedstaats verarbeitet werden.')"
DS="$DS$(heading3 'SSL- bzw. TLS-Verschlüsselung')"
DS="$DS$(para 'Diese Seite nutzt aus Sicherheitsgründen und zum Schutz der Übertragung vertraulicher Inhalte, wie zum Beispiel Anfragen, die Sie an uns als Seitenbetreiber senden, eine SSL- bzw. TLS-Verschlüsselung. Eine verschlüsselte Verbindung erkennen Sie daran, dass die Adresszeile des Browsers von „http://“ auf „https://“ wechselt und an dem Schloss-Symbol in Ihrer Browserzeile.')"
DS="$DS$(para 'Wenn die SSL- bzw. TLS-Verschlüsselung aktiviert ist, können die Daten, die Sie an uns übermitteln, nicht von Dritten mitgelesen werden.')"

DS="$DS$(heading '4. Datenerfassung auf dieser Website')"
DS="$DS$(heading3 'Server-Log-Dateien')"
DS="$DS$(para 'Der Provider der Seiten erhebt und speichert automatisch Informationen in so genannten Server-Log-Dateien, die Ihr Browser automatisch an uns übermittelt. Dies sind:')"
DS="$DS$(bullets \
  'Browsertyp und Browserversion' \
  'verwendetes Betriebssystem' \
  'Referrer URL' \
  'Hostname des zugreifenden Rechners' \
  'Uhrzeit der Serveranfrage' \
  'IP-Adresse')"
DS="$DS$(para 'Eine Zusammenführung dieser Daten mit anderen Datenquellen wird nicht vorgenommen.')"
DS="$DS$(para 'Die Erfassung dieser Daten erfolgt auf Grundlage von Art. 6 Abs. 1 lit. f DSGVO. Der Websitebetreiber hat ein berechtigtes Interesse an der technisch fehlerfreien Darstellung und der Optimierung seiner Website – hierzu müssen die Server-Log-Dateien erfasst werden.')"
DS="$DS$(heading3 'Anfrage per E-Mail oder Telefon')"
DS="$DS$(para 'Wenn Sie uns per E-Mail oder Telefon kontaktieren, wird Ihre Anfrage inklusive aller daraus hervorgehenden personenbezogenen Daten (Name, Anfrage) zum Zwecke der Bearbeitung Ihres Anliegens bei uns gespeichert und verarbeitet. Diese Daten geben wir nicht ohne Ihre Einwilligung weiter.')"
DS="$DS$(para 'Die Verarbeitung dieser Daten erfolgt auf Grundlage von Art. 6 Abs. 1 lit. b DSGVO, sofern Ihre Anfrage mit der Erfüllung eines Vertrags zusammenhängt oder zur Durchführung vorvertraglicher Maßnahmen erforderlich ist. In allen übrigen Fällen beruht die Verarbeitung auf unserem berechtigten Interesse an der effektiven Bearbeitung der an uns gerichteten Anfragen (Art. 6 Abs. 1 lit. f DSGVO) oder auf Ihrer Einwilligung (Art. 6 Abs. 1 lit. a DSGVO), sofern diese abgefragt wurde; die Einwilligung ist jederzeit widerrufbar.')"
DS="$DS$(para 'Die von Ihnen an uns per Kontaktanfragen übersandten Daten verbleiben bei uns, bis Sie uns zur Löschung auffordern, Ihre Einwilligung zur Speicherung widerrufen oder der Zweck für die Datenspeicherung entfällt (z. B. nach abgeschlossener Bearbeitung Ihres Anliegens). Zwingende gesetzliche Bestimmungen – insbesondere gesetzliche Aufbewahrungsfristen – bleiben unberührt.')"

PRIVACY_ID=$(ensure_page privacy-policy "Datenschutzerklärung" "" "$DS")
$WP post update "$PRIVACY_ID" --post_status=publish >/dev/null
IMPRINT="$(heading 'Angaben gemäß § 5 DDG')"
IMPRINT="$IMPRINT$(para 'Lions Club Musterstadt<br>Präsident Lions Club Musterstadt<br>Musterstraße 1<br>12345 Musterstadt')"
IMPRINT="$IMPRINT$(heading 'Kontakt')"
IMPRINT="$IMPRINT$(para "E-Mail: <a href=\"mailto:$CONTACT_EMAIL\">$CONTACT_EMAIL</a>")"
IMPRINT="$IMPRINT$(heading 'Verbraucherstreitbeilegung/Universalschlichtungsstelle')"
IMPRINT="$IMPRINT$(para 'Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.')"
IMPRINT="$IMPRINT$(heading 'Zentrale Kontaktstelle nach dem Digital Services Act – DSA (Verordnung (EU) 2022/2065)')"
IMPRINT="$IMPRINT$(para 'Unsere zentrale Kontaktstelle für Nutzer und Behörden nach Art. 11, 12 DSA erreichen Sie wie folgt:')"
IMPRINT="$IMPRINT$(para "E-Mail: <a href=\"mailto:$CONTACT_EMAIL\">$CONTACT_EMAIL</a>")"
IMPRINT="$IMPRINT$(para 'Die für den Kontakt zur Verfügung stehenden Sprachen sind: Deutsch, Englisch.')"
ensure_page imprint "Impressum" "" "$IMPRINT" >/dev/null

$WP option update show_on_front page >/dev/null
$WP option update page_on_front "$HOME_ID" >/dev/null
$WP option update page_for_posts "$STORIES_ID" >/dev/null
$WP option update wp_page_for_privacy_policy "$PRIVACY_ID" >/dev/null

echo "==> Categories and posts"
ensure_term() { $WP term get category "$1" --by=slug --field=term_id 2>/dev/null || $WP term create category "$2" --slug="$1" --porcelain; }
CAT_SERVICE=$(ensure_term community-service "Gemeinnützige Arbeit")
CAT_EVENTS=$(ensure_term veranstaltungen "Veranstaltungen")
CAT_DONATE=$(ensure_term spenden "Spenden")
CAT_CLUB=$(ensure_term clubleben "Clubleben")

# ensure_post <slug> <title> <category-id> <date YYYY-MM-DD> <excerpt> <content>
ensure_post() {
  local slug="$1" title="$2" cat="$3" date="$4" excerpt="$5" content="$6"
  if [ -n "$($WP post list --post_type=post --name="$slug" --field=ID --posts_per_page=1)" ]; then return; fi
  $WP post create --post_type=post --post_status=publish --post_name="$slug" --post_title="$title" \
    --post_category="$cat" --post_excerpt="$excerpt" --post_content="$content" \
    --post_date="$date 10:00:00" >/dev/null
}

ensure_post save-the-date-konzertabend-2027 "Save the date: 8. April 2027" "$CAT_EVENTS" 2026-09-01 \
  "Bereits zum vierten Mal in Folge lädt der Lions Club Musterstadt zum Konzertabend mit dem Landespolizeiorchester Musterland in die Pilgerkirche Musterberg ein." \
  "$(para 'Bereits zum vierten Mal in Folge lädt der Lions Club Musterstadt zum Konzertabend mit dem <strong>Landespolizeiorchester Musterland</strong> in die Pilgerkirche Musterberg ein.')$(table \
    'Termin' '8. April 2027' \
    'Ort'    'Pilgerkirche Musterberg' \
    'Gäste'  'Landespolizeiorchester Musterland')$(para 'Weitere Informationen folgen – jetzt vormerken!')"

ensure_post spendenuebergabe-an-drei-regionale-projekte "Spendenübergabe an drei regionale Projekte" "$CAT_DONATE" 2025-07-02 \
  "7.500 Euro aus dem Benefizkonzert des Landespolizeiorchesters gehen an drei Projekte in der Region." \
  "$(para 'Das Benefizkonzert des Landespolizeiorchesters Musterland am 3. April 2025 in der Musterberger Pilgerkirche hat 7.500 Euro eingebracht. Am 2. Juli 2025 wurde der Scheck in der Einrichtung der Förder- und Wohnstätten Musterland gGmbH in Musterheim übergeben.')$(para 'Der Erlös verteilt sich auf drei Projekte:')$(bullets \
    '<strong>Projekt Tierwelt</strong> – eine Tagesförderstätte, in der Menschen mit schweren Behinderungen nach ihren Möglichkeiten mit geretteten Tieren arbeiten.' \
    '<strong>Projekt Snoezelen</strong> – ein geschützter Raum, in dem Menschen mit schwersten und mehrfachen Behinderungen ihre Sinne bewusst wahrnehmen können.' \
    '<strong>Projekt Spielraum</strong> – gemeinsame Spielaktivitäten für Mädchen mit Migrationshintergrund aus sozial schwachen Familien, zusammen mit der Hochschule Beispielstadt und dem Jugendzentrum Musterstadt.')$(para 'Ein weiteres Benefizkonzert ist bereits in Planung.')"

ensure_post amtsuebergabe-2024-2025 "Amtsübergabe 2024/2025" "$CAT_CLUB" 2025-07-01 \
  "Klaus Mustermann übergibt die Präsidentschaft an Erika Musterfrau – gefeiert wurde in der Gutsschänke in Beispieldorf." \
  "$(para 'Bei sommerlichem Wetter traf sich der Lions Club Musterstadt in der Gutsschänke in Beispieldorf zur Amtsübergabe.')$(para 'Der scheidende Präsident Klaus Mustermann blickte auf die zahlreichen Aktivitäten des vergangenen Clubjahres zurück und dankte den Mitgliedern für ihr Engagement. Anschließend übergab er die Amtskette an seine Nachfolgerin Erika Musterfrau.')$(para 'Musterfrau bedankte sich für das entgegengebrachte Vertrauen und kündigte ein ereignisreiches und anspruchsvolles Jahresprogramm an. Der Nachmittag klang im Kreis der Mitglieder aus.')"

ensure_post tafel-feiert-mit-langer-tafel "Tafel feiert mit langer Tafel – Lions packen mit an" "$CAT_SERVICE" 2025-05-21 \
  "Rund 50 Lions haben beim 25-jährigen Jubiläum der Tafel Beispielstadt auf dem Marktplatz mit angepackt." \
  "$(para 'Zum 25-jährigen Bestehen der Tafel Beispielstadt wurde am 21. Mai 2025 auf dem Marktplatz eine lange Tafel gedeckt. Rund 50 Lions aus drei benachbarten Clubs und dem Lions Club Musterstadt halfen beim Ausgeben von Speisen und Getränken.')$(para 'Die Tafel Beispielstadt wurde im Jahr 2000 nach bewährtem Vorbild gegründet. Heute versorgt sie wöchentlich rund 1.000 Haushalte mit etwa 3.000 Menschen.')$(quote 'Wir alle zusammen haben gezeigt, was We serve bedeutet.' 'Max Mustermann')"

echo "==> Featured images"
# The demo posts ship without media. A featured image has to be a real
# attachment, and WordPress rejects SVG uploads, so a Lions-styled placeholder
# JPEG is generated (bin/placeholder-image.php) and imported once per post.
# set_dummy_thumbnail <post-slug> <variant> <alt text>
set_dummy_thumbnail() {
  local slug="$1" variant="$2" alt="$3" id file
  id=$($WP post list --post_type=post --name="$slug" --field=ID --posts_per_page=1 | head -n1)
  [ -n "$id" ] || return 0
  # Idempotent: never overwrite an image an editor has chosen.
  [ -z "$($WP post meta get "$id" _thumbnail_id 2>/dev/null)" ] || return 0

  file="/tmp/lions-placeholder-$slug.jpg"
  # Hero dimensions: the single template renders the thumbnail full-bleed.
  php "$SCRIPT_DIR/placeholder-image.php" "$file" 1920 1080 "$variant"
  $WP media import "$file" --post_id="$id" --featured_image \
    --title="$($WP post get "$id" --field=post_title)" --alt="$alt" >/dev/null
  rm -f "$file"
}

set_dummy_thumbnail save-the-date-konzertabend-2027 0 "Platzhalterbild fuer den Konzertabend"

echo "==> Menus"
ensure_menu() { $WP term list nav_menu --name="$1" --field=term_id | head -n1; }
create_menu() { local id; id=$(ensure_menu "$1"); if [ -z "$id" ]; then id=$($WP menu create "$1" --porcelain); fi; echo "$id"; }
menu_has_items() { [ "$($WP menu item list "$1" --format=count)" -gt 0 ]; }

PRIMARY=$(create_menu "Hauptnavigation")
if ! menu_has_items "$PRIMARY"; then
  # No "about" landing page exists, so the group is a custom item pointing at its first child.
  P_CLUB=$($WP menu item add-custom "$PRIMARY" "Lions Club Musterstadt" "$($WP post get "$(page_id our-history)" --field=url)" --porcelain)
  $WP menu item add-post "$PRIMARY" "$(page_id our-history)" --parent-id="$P_CLUB" >/dev/null
  $WP menu item add-post "$PRIMARY" "$(page_id leadership)" --parent-id="$P_CLUB" >/dev/null
  # "Mitmachen" links straight to the merged page rather than to the parent it lives under.
  P_INV=$($WP menu item add-post "$PRIMARY" "$(page_id volunteer)" --porcelain)
  $WP menu item add-post "$PRIMARY" "$(page_id donate)" --parent-id="$P_INV" >/dev/null
  $WP menu item add-post "$PRIMARY" "$STORIES_ID" >/dev/null
fi
$WP menu location assign "$PRIMARY" primary >/dev/null 2>&1 || true

LEGAL=$(create_menu "Rechtliches")
if ! menu_has_items "$LEGAL"; then
  $WP menu item add-post "$LEGAL" "$PRIVACY_ID" >/dev/null
  $WP menu item add-post "$LEGAL" "$(page_id imprint)" >/dev/null
fi
$WP menu location assign "$LEGAL" legal >/dev/null 2>&1 || true

echo "==> Theme settings (Customizer defaults)"
$WP theme mod set lions_cta_join_url "$($WP post get "$(page_id volunteer)" --field=url)" >/dev/null
$WP theme mod set lions_cta_donate_url "$($WP post get "$(page_id donate)" --field=url)" >/dev/null
$WP theme mod set lions_contact_organization "${WORDPRESS_SITE_TITLE:-Lions Club Musterstadt}" >/dev/null
$WP theme mod set lions_contact_phone "+49 30 23125 100" >/dev/null
$WP theme mod set lions_contact_email "$CONTACT_EMAIL" >/dev/null
$WP theme mod set lions_social_facebook "https://www.facebook.com/" >/dev/null
$WP theme mod set lions_social_instagram "https://www.instagram.com/" >/dev/null

# WP-CLI runs as root, so media it imported is root-owned; hand it back to the
# web server user or wp-admin uploads into the same folders start failing.
if [ "$(id -u)" = "0" ]; then
  chown -R www-data:www-data "$WP_PATH/wp-content/uploads" 2>/dev/null || true
fi

echo
echo "Done. Site: $URL   Admin: $URL/wp-admin/  (user: ${WORDPRESS_ADMIN_USER:-admin})"
