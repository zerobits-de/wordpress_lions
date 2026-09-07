<?php
/**
 * Site object exposed to Twig as `site`.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme;

use Lions\Theme\Functions\Customizer;
use Timber\Image;
use Timber\Site as TimberSite;
use Timber\Timber;

/**
 * Extends Timber\Site with organisation data editors manage in the Customizer
 * (Appearance > Customize > Lions International).
 *
 * Twig usage: `site.name`, `site.cta.join.url`, `site.social`, `site.contact.phone`, `site.logo`.
 */
class Site extends TimberSite {

	/**
	 * Primary calls to action shown in the header and mobile navigation.
	 *
	 * @return array<string, array{label: string, url: string}>
	 */
	public function cta(): array {
		return array(
			'join'   => array(
				'label' => __( 'Join', 'lions-theme' ),
				'url'   => Customizer::mod( 'cta_join_url' ),
			),
			'donate' => array(
				'label' => __( 'Donate', 'lions-theme' ),
				'url'   => Customizer::mod( 'cta_donate_url' ),
			),
		);
	}

	/**
	 * Social profiles that have a URL configured.
	 *
	 * @return array<int, array{network: string, label: string, url: string}>
	 */
	public function social(): array {
		$networks = array(
			'facebook'  => 'Facebook',
			'instagram' => 'Instagram',
		);

		$links = array();

		foreach ( $networks as $network => $label ) {
			$url = Customizer::mod( 'social_' . $network );

			if ( '' === $url ) {
				continue;
			}

			$links[] = array(
				'network' => $network,
				'label'   => $label,
				'url'     => $url,
			);
		}

		return $links;
	}

	/**
	 * Organisation contact details. `email` is shown in the footer; the rest
	 * feeds the Organization JSON-LD in Seo.
	 *
	 * @return array{organization: string, phone: string, email: string}
	 */
	public function contact(): array {
		return array(
			'organization' => Customizer::mod( 'contact_organization' ),
			'phone'        => Customizer::mod( 'contact_phone' ),
			'email'        => Customizer::mod( 'contact_email' ),
		);
	}

	/**
	 * Custom logo uploaded through the Customizer, or null to fall back to the
	 * bundled placeholder mark.
	 */
	public function logo(): ?Image {
		$logo_id = (int) get_theme_mod( 'custom_logo', 0 );

		if ( $logo_id <= 0 ) {
			return null;
		}

		$image = Timber::get_image( $logo_id );

		return $image instanceof Image ? $image : null;
	}
}
