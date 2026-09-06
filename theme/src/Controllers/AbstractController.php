<?php
/**
 * Base controller.
 *
 * @package Lions\Theme
 */

declare(strict_types=1);

namespace Lions\Theme\Controllers;

use Timber\Timber;

/**
 * A controller maps one WordPress template-hierarchy entry point to a Twig
 * template and prepares the context it needs.
 *
 *   WordPress -> {template}.php -> Controller::render() -> Timber::render(twig, context)
 */
abstract class AbstractController {

	/**
	 * Candidate Twig templates in priority order (first found wins).
	 *
	 * @return array<int, string>
	 */
	abstract protected function templates(): array;

	/**
	 * Context passed to Twig. Extend Timber's global context; never replace it.
	 *
	 * @return array<string, mixed>
	 */
	protected function context(): array {
		return Timber::context();
	}

	/**
	 * Render the first matching template.
	 */
	public function render(): void {
		Timber::render( $this->templates(), $this->context() );
	}
}
