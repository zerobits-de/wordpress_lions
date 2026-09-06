<?php
/**
 * Customizer settings for organisation data.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Functions;

use Lions\Theme\Registrable;
use WP_Customize_Manager;

/**
 * "Lions International" panel in Appearance > Customize.
 *
 * Editors manage calls to action, social profiles and contact details here
 * without touching templates. Values are read via Customizer::mod().
 */
final class Customizer implements Registrable {

	private const PANEL = 'lions';

	/**
	 * Setting definitions: id => [label, section, type, default, sanitize].
	 *
	 * @return array<string, array{label: string, section: string, type: string, default: string, sanitize: callable}>
	 */
	private static function settings(): array {
		return array(
			'cta_join_url'         => array(
				'label'    => __( 'Join URL', 'lions-theme' ),
				'section'  => 'cta',
				'type'     => 'url',
				'default'  => home_url( '/get-involved/' ),
				'sanitize' => 'esc_url_raw',
			),
			'cta_donate_url'       => array(
				'label'    => __( 'Donate URL', 'lions-theme' ),
				'section'  => 'cta',
				'type'     => 'url',
				'default'  => home_url( '/get-involved/donate/' ),
				'sanitize' => 'esc_url_raw',
			),
			'social_facebook'      => array(
				'label'    => 'Facebook',
				'section'  => 'social',
				'type'     => 'url',
				'default'  => '',
				'sanitize' => 'esc_url_raw',
			),
			'social_instagram'     => array(
				'label'    => 'Instagram',
				'section'  => 'social',
				'type'     => 'url',
				'default'  => '',
				'sanitize' => 'esc_url_raw',
			),
			'social_linkedin'      => array(
				'label'    => 'LinkedIn',
				'section'  => 'social',
				'type'     => 'url',
				'default'  => '',
				'sanitize' => 'esc_url_raw',
			),
			'social_x'             => array(
				'label'    => 'X',
				'section'  => 'social',
				'type'     => 'url',
				'default'  => '',
				'sanitize' => 'esc_url_raw',
			),
			'social_youtube'       => array(
				'label'    => 'YouTube',
				'section'  => 'social',
				'type'     => 'url',
				'default'  => '',
				'sanitize' => 'esc_url_raw',
			),
			'contact_organization' => array(
				'label'    => __( 'Organisation name', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'text',
				'default'  => __( 'Lions International', 'lions-theme' ),
				'sanitize' => 'sanitize_text_field',
			),
			'contact_address'      => array(
				'label'    => __( 'Postal address (one line per row)', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'textarea',
				'default'  => "Example Street 1\n12345 Example City",
				'sanitize' => 'sanitize_textarea_field',
			),
			'contact_phone'        => array(
				'label'    => __( 'Phone', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'text',
				'default'  => '+1 555 0100',
				'sanitize' => 'sanitize_text_field',
			),
			'contact_email'        => array(
				'label'    => __( 'Email', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'email',
				'default'  => 'info@example.org',
				'sanitize' => 'sanitize_email',
			),
			'footer_legal'         => array(
				'label'    => __( 'Footer legal text', 'lions-theme' ),
				'section'  => 'contact',
				'type'     => 'textarea',
				'default'  => __( 'Placeholder legal notice. Replace with the organisation\'s registered details and charitable status.', 'lions-theme' ),
				'sanitize' => 'sanitize_textarea_field',
			),
		);
	}

	/**
	 * Attach hooks.
	 */
	public function register(): void {
		add_action( 'customize_register', array( $this, 'customize_register' ) );
	}

	/**
	 * Read a theme mod with the documented default.
	 *
	 * @param string $id Setting id without the `lions_` prefix.
	 */
	public static function mod( string $id ): string {
		$settings = self::settings();

		if ( ! isset( $settings[ $id ] ) ) {
			return '';
		}

		$value = get_theme_mod( 'lions_' . $id, $settings[ $id ]['default'] );

		return is_string( $value ) ? $value : '';
	}

	/**
	 * Register panel, sections, settings and controls.
	 *
	 * @param WP_Customize_Manager $wp_customize Customizer manager.
	 */
	public function customize_register( WP_Customize_Manager $wp_customize ): void {
		$wp_customize->add_panel(
			self::PANEL,
			array(
				'title'    => __( 'Lions International', 'lions-theme' ),
				'priority' => 30,
			)
		);

		$sections = array(
			'cta'     => __( 'Calls to action', 'lions-theme' ),
			'social'  => __( 'Social profiles', 'lions-theme' ),
			'contact' => __( 'Contact & legal', 'lions-theme' ),
		);

		foreach ( $sections as $id => $title ) {
			$wp_customize->add_section(
				self::PANEL . '_' . $id,
				array(
					'title' => $title,
					'panel' => self::PANEL,
				)
			);
		}

		foreach ( self::settings() as $id => $setting ) {
			$wp_customize->add_setting(
				'lions_' . $id,
				array(
					'type'              => 'theme_mod',
					'default'           => $setting['default'],
					'sanitize_callback' => $setting['sanitize'],
				)
			);

			$wp_customize->add_control(
				'lions_' . $id,
				array(
					'label'   => $setting['label'],
					'section' => self::PANEL . '_' . $setting['section'],
					'type'    => $setting['type'],
				)
			);
		}
	}
}
