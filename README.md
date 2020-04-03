# localize-xibs

Localize-xibs allows you to easily reference translations from Interface Builder, without having to
deal with Object IDs and multiple `.strings` files.

It offers the following benefits:

1. Keep all your translations in one file per locale, instead of different `.strings` files throughout your project.
1. You can reference your translations directly from Interface Builder, so no more dealing with IB Object IDs,
   strings files that get out of sync, etc.
1. You can easily see in Interface Builder what translation is used in what place.

## Installation with mint

```
mint install wvteijlingen/localize-xibs
```

## Usage

1. Add all your translations in centralized `.strings` files in your project, for example:
   - `MyProject/Resources/en.lproj/Translations.strings`
   - `MyProject/Resources/de.lproj/Translations.strings`.
1. In the Xcode file inspector, configure your XIBs to be localized using "Localizable Strings".
1. Wherever you normally enter text using Interface Builder, you can reference your translation using:
   `t:my_translation_key`.
1. In the root of your project run
   `localize-xibs MyProject/Resources/en.lproj/Translations.strings MyProject/Resources/de.lproj/Translations.strings`
   to update all your XIB localizations.

## Use as Run Script in Xcode

You can add a Run Script build phase that does the localization for you. That way you can just add translations to your centralized file, and your XIB strings files will automatically be updated on each build. An added benefit is that when adding the `--strict` flag, this will throw Xcode build errors when you reference an unknown translation.

Simply add a `Run Script` phase with the localize-xibs command. Make sure it is positioned before the "Copy Bundle Resources" phase.

For example:

```
localize-xibs MyProject/Resources/en.lproj/Translations.strings MyProject/Resources/de.lproj/Translations.strings --strict
```
