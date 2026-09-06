#!/usr/bin/env bash
# Complete the WordPress installation and seed demo content with WP-CLI.
# Runs INSIDE the wordpress container:  make install
#
# Idempotent: safe to run repeatedly. Existing content is left untouched.
set -euo pipefail

WP="wp --allow-root --path=/var/www/html"
URL="http://localhost:${WORDPRESS_PORT:-8080}"

echo "==> Waiting for the database"
for i in $(seq 1 30); do
  if $WP db check >/dev/null 2>&1; then break; fi
  sleep 2
done

if ! $WP core is-installed >/dev/null 2>&1; then
  echo "==> Installing WordPress at $URL"
  $WP core install \
    --url="$URL" \
    --title="${WORDPRESS_SITE_TITLE:-Lions International}" \
    --admin_user="${WORDPRESS_ADMIN_USER:-admin}" \
    --admin_password="${WORDPRESS_ADMIN_PASSWORD:-admin}" \
    --admin_email="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}" \
    --locale="${WORDPRESS_LOCALE:-en_US}" \
    --skip-email
else
  echo "==> WordPress already installed"
fi

echo "==> Activating theme"
$WP theme activate lions-theme
$WP option update blogdescription "Serving communities, together." >/dev/null
$WP rewrite structure '/%postname%/' >/dev/null
$WP option update timezone_string 'Europe/Berlin' >/dev/null

# ---------------------------------------------------------------------------
page_id() { $WP post list --post_type=page --name="$1" --field=ID --posts_per_page=1 | head -n1; }

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

echo "==> Removing WordPress sample content"
for slug in hello-world sample-page; do
  for id in $($WP post list --post_type=post,page --name="$slug" --field=ID); do $WP post delete "$id" --force >/dev/null; done
done
$WP comment delete 1 --force >/dev/null 2>&1 || true

echo "==> Pages"
HOME_ID=$(ensure_page home "Home" "" "$(para 'Lions are neighbours, colleagues and friends who decided that the best answer to a local need is to roll up their sleeves. Clubs in more than two hundred countries and geographic areas bring people together around one simple idea: communities improve when people serve them.')$(para 'From sight screenings and food drives to youth programmes and disaster response, every project starts with someone who cares. Our foundation amplifies that care with grants that turn local ideas into lasting change.')")
STORIES_ID=$(ensure_page stories "Stories" "" "$(para 'News and stories from clubs around the world.')")
ABOUT_ID=$(ensure_page about-us "About Us" "" "$(para 'We are a global network of volunteers united by a simple promise: where there is a need, there is a Lion. Since our founding, members have served their communities through hands-on projects that improve health, support young people and protect the environment.')$(heading 'What we believe')$(para 'Service is most powerful when it is local, practical and shared. Every club decides for itself where help is needed most, and every member brings their own skills to the table.')$(heading 'How we work')$(para 'Clubs meet regularly, plan projects together and partner with schools, hospitals and other organisations. Our international association provides training, tools and a global foundation that funds larger initiatives.')")
ensure_page our-history "Our History" about-us "$(para 'Our story began with a small group of business people who wanted to look beyond their own interests and serve their communities. That idea spread quickly across borders and continents.')$(para 'Today the association is one of the largest service organisations in the world, but the founding idea has not changed: local people solving local problems.')" >/dev/null
ensure_page leadership "Leadership" about-us "$(para 'Volunteer leaders at club, district and international level guide the organisation. This page can hold the current board, officers and their responsibilities.')" >/dev/null
IMPACT_ID=$(ensure_page our-impact "Our Impact" "" "$(para 'Our global causes give clubs a shared direction while leaving room for local priorities. Explore the areas where Lions concentrate their service.')")
ensure_page vision "Vision" our-impact "$(para 'Preventing avoidable blindness has been at the heart of our work for a century: eye screenings, cataract surgeries, eyeglass recycling and support for people living with low vision.')" >/dev/null
ensure_page youth "Youth" our-impact "$(para 'Leadership camps, scholarships and Leo clubs give young people a place to lead through service and to build skills that last a lifetime.')" >/dev/null
ensure_page hunger "Hunger" our-impact "$(para 'Food banks, school meal programmes and community gardens make sure no neighbour goes without a meal.')" >/dev/null
ensure_page environment "Environment" our-impact "$(para 'Tree planting, clean-up days and conservation projects protect the places we all share.')" >/dev/null
INVOLVED_ID=$(ensure_page get-involved "Get Involved" "" "$(para 'Join a club near you, volunteer for a single project or support the foundation. Whatever your time and talents, there is a place for you.')$(heading 'Become a member')$(para 'Membership is open to anyone who wants to serve. Contact a club near you or use the form on this page to get in touch.')")
ensure_page volunteer "Volunteer" get-involved "$(para 'Not ready to join? Many clubs welcome volunteers for individual projects. Bring a friend and lend a hand.')" >/dev/null
ensure_page donate "Donate" get-involved "$(para 'Gifts to the foundation fund grants for sight, youth, disaster relief and humanitarian projects worldwide. This page is a placeholder for the donation flow.')" >/dev/null
CONTACT_ID=$(ensure_page contact "Contact" "" "$(para 'Placeholder contact page. Add a contact form plugin or your preferred contact details here.')")
PRIVACY_ID=$(ensure_page privacy-policy "Privacy Policy" "" "$(para 'Placeholder privacy policy. Replace with the organisation’s actual policy.')")
ensure_page imprint "Imprint" "" "$(para 'Placeholder legal notice / imprint.')" >/dev/null

$WP option update show_on_front page >/dev/null
$WP option update page_on_front "$HOME_ID" >/dev/null
$WP option update page_for_posts "$STORIES_ID" >/dev/null
$WP option update wp_page_for_privacy_policy "$PRIVACY_ID" >/dev/null

echo "==> Categories and posts"
ensure_term() { $WP term get category "$1" --by=slug --field=term_id 2>/dev/null || $WP term create category "$2" --slug="$1" --porcelain; }
CAT_SERVICE=$(ensure_term community-service "Community Service")
CAT_VISION=$(ensure_term vision "Vision")
CAT_YOUTH=$(ensure_term youth "Youth")
CAT_ENV=$(ensure_term environment "Environment")
CAT_RELIEF=$(ensure_term disaster-relief "Disaster Relief")

# ensure_post <slug> <title> <category-id> <days-ago> <excerpt> <content>
ensure_post() {
  local slug="$1" title="$2" cat="$3" days="$4" excerpt="$5" content="$6"
  if [ -n "$($WP post list --post_type=post --name="$slug" --field=ID --posts_per_page=1)" ]; then return; fi
  $WP post create --post_type=post --post_status=publish --post_name="$slug" --post_title="$title" \
    --post_category="$cat" --post_excerpt="$excerpt" --post_content="$content" \
    --post_date="$(date -d "-$days days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v-"$days"d '+%Y-%m-%d %H:%M:%S')" >/dev/null
}

ensure_post free-eye-screenings-reach-two-thousand-students "Free eye screenings reach two thousand students" "$CAT_VISION" 3 \
  "Volunteers from six clubs teamed up with local schools to screen every child in the district." \
  "$(para 'Over three Saturdays, volunteers from six clubs set up screening stations in school gyms across the district. Two thousand children had their eyes tested, and more than three hundred received glasses at no cost to their families.')$(para 'Teachers reported that several students who had struggled with reading were simply unable to see the board. A pair of glasses changed that overnight.')"
ensure_post community-garden-opens-behind-the-library "Community garden opens behind the library" "$CAT_ENV" 9 \
  "An unused lot is now forty raised beds, a tool shed and a gathering place for the neighbourhood." \
  "$(para 'What used to be a gravel lot behind the public library is now a community garden with forty raised beds, a tool shed and a shaded gathering area. Club members built the beds over two weekends with donated timber.')$(para 'Half the beds are reserved for the food bank; the rest are rented to families for a symbolic fee that funds seeds and water.')"
ensure_post leo-club-leads-weekend-clean-up "Leo club leads riverside weekend clean-up" "$CAT_YOUTH" 16 \
  "Sixty young volunteers collected more than a tonne of waste along the river path." \
  "$(para 'The local Leo club organised its largest project yet: a two-day clean-up along the river path. Sixty young volunteers, many taking part for the first time, collected more than a tonne of waste.')$(para 'The club is now working with the city on permanent recycling points along the route.')"
ensure_post emergency-grant-supports-flood-response "Emergency grant supports flood response" "$CAT_RELIEF" 24 \
  "A rapid grant from the foundation funded clean water, blankets and hot meals within 48 hours." \
  "$(para 'When heavy rain flooded three villages, clubs in the district requested an emergency grant. Within 48 hours the foundation approved funding for clean water, blankets and hot meals for four hundred families.')$(para 'Members are now helping households replace damaged furniture and school supplies.')"
ensure_post hearing-aid-recycling-drive-doubles-donations "Hearing aid recycling drive doubles donations" "$CAT_SERVICE" 33 \
  "Collection boxes in pharmacies and opticians brought in twice as many devices as last year." \
  "$(para 'Placing collection boxes in pharmacies and opticians turned out to be the key: the annual recycling drive received twice as many hearing aids as the previous year.')$(para 'Refurbished devices are distributed through partner clinics to people who could not otherwise afford them.')"
ensure_post new-club-charters-in-the-harbour-district "New club charters in the harbour district" "$CAT_SERVICE" 41 \
  "Twenty-eight founding members celebrated the charter of the district’s newest club." \
  "$(para 'Twenty-eight founding members celebrated the charter of the newest club in the harbour district. Their first project, a breakfast programme at the primary school, starts next month.')$(para 'The club meets on the first Tuesday of every month and welcomes guests.')"

echo "==> Menus"
ensure_menu() { $WP term list nav_menu --name="$1" --field=term_id | head -n1; }
create_menu() { local id; id=$(ensure_menu "$1"); if [ -z "$id" ]; then id=$($WP menu create "$1" --porcelain); fi; echo "$id"; }
menu_has_items() { [ "$($WP menu item list "$1" --format=count)" -gt 0 ]; }

PRIMARY=$(create_menu "Primary")
if ! menu_has_items "$PRIMARY"; then
  P_ABOUT=$($WP menu item add-post "$PRIMARY" "$ABOUT_ID" --porcelain)
  $WP menu item add-post "$PRIMARY" "$(page_id our-history)" --parent-id="$P_ABOUT" >/dev/null
  $WP menu item add-post "$PRIMARY" "$(page_id leadership)" --parent-id="$P_ABOUT" >/dev/null
  P_IMPACT=$($WP menu item add-post "$PRIMARY" "$IMPACT_ID" --porcelain)
  for s in vision youth hunger environment; do $WP menu item add-post "$PRIMARY" "$(page_id $s)" --parent-id="$P_IMPACT" >/dev/null; done
  P_INV=$($WP menu item add-post "$PRIMARY" "$INVOLVED_ID" --porcelain)
  $WP menu item add-post "$PRIMARY" "$(page_id volunteer)" --parent-id="$P_INV" >/dev/null
  $WP menu item add-post "$PRIMARY" "$(page_id donate)" --parent-id="$P_INV" >/dev/null
  $WP menu item add-post "$PRIMARY" "$STORIES_ID" >/dev/null
fi
$WP menu location assign "$PRIMARY" primary >/dev/null 2>&1 || true

UTILITY=$(create_menu "Utility")
if ! menu_has_items "$UTILITY"; then
  $WP menu item add-custom "$UTILITY" "Foundation" "https://example.org/foundation" >/dev/null
  $WP menu item add-custom "$UTILITY" "Member Portal" "https://example.org/portal" --target=_blank >/dev/null
  $WP menu item add-post "$UTILITY" "$INVOLVED_ID" --title="Find a Club" >/dev/null
  $WP menu item add-post "$UTILITY" "$CONTACT_ID" >/dev/null
fi
$WP menu location assign "$UTILITY" utility >/dev/null 2>&1 || true

F1=$(create_menu "About")
if ! menu_has_items "$F1"; then
  $WP menu item add-post "$F1" "$ABOUT_ID" --title="Who we are" >/dev/null
  $WP menu item add-post "$F1" "$(page_id our-history)" >/dev/null
  $WP menu item add-post "$F1" "$(page_id leadership)" >/dev/null
  $WP menu item add-post "$F1" "$STORIES_ID" >/dev/null
fi
$WP menu location assign "$F1" footer_1 >/dev/null 2>&1 || true

F2=$(create_menu "Our Causes")
if ! menu_has_items "$F2"; then
  for s in vision youth hunger environment; do $WP menu item add-post "$F2" "$(page_id $s)" >/dev/null; done
fi
$WP menu location assign "$F2" footer_2 >/dev/null 2>&1 || true

F3=$(create_menu "Connect")
if ! menu_has_items "$F3"; then
  $WP menu item add-post "$F3" "$INVOLVED_ID" --title="Join a club" >/dev/null
  $WP menu item add-post "$F3" "$(page_id volunteer)" >/dev/null
  $WP menu item add-post "$F3" "$(page_id donate)" >/dev/null
  $WP menu item add-post "$F3" "$CONTACT_ID" >/dev/null
fi
$WP menu location assign "$F3" footer_3 >/dev/null 2>&1 || true

LEGAL=$(create_menu "Legal")
if ! menu_has_items "$LEGAL"; then
  $WP menu item add-post "$LEGAL" "$PRIVACY_ID" >/dev/null
  $WP menu item add-post "$LEGAL" "$(page_id imprint)" >/dev/null
fi
$WP menu location assign "$LEGAL" legal >/dev/null 2>&1 || true

echo "==> Theme settings (Customizer defaults)"
$WP theme mod set lions_cta_join_url "$($WP post get "$INVOLVED_ID" --field=url)" >/dev/null
$WP theme mod set lions_cta_donate_url "$($WP post get "$(page_id donate)" --field=url)" >/dev/null
$WP theme mod set lions_social_facebook "https://www.facebook.com/" >/dev/null
$WP theme mod set lions_social_instagram "https://www.instagram.com/" >/dev/null
$WP theme mod set lions_social_linkedin "https://www.linkedin.com/" >/dev/null
$WP theme mod set lions_social_youtube "https://www.youtube.com/" >/dev/null

echo
echo "Done. Site: $URL   Admin: $URL/wp-admin/  (user: ${WORDPRESS_ADMIN_USER:-admin})"
