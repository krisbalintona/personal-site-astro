;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((astro-mode . ((eval . (eglot-ensure))))
 (astro-ts-mode . ((eval . (eglot-ensure))))
 (typescript-ts-mode . ((eval . (eglot-ensure))
                        (apheleia-formatter . biome)))
 (json-ts-mode . ((apheleia-formatter . biome)))
 (js-ts-mode . ((eval . (eglot-ensure))
                (apheleia-formatter . biome)))
 (tsx-ts-mode . ((apheleia-formatter . biome)))
 (nil . ((compile-command . "npm run fix && npm run build")
         (tab-width . 2))))
