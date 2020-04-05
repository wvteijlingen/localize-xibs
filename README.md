<p align="center">
  <a href="https://codecov.io/gh/wvteijlingen/localize-xibs">
    <img src="https://codecov.io/gh/wvteijlingen/localize-xibs/branch/master/graph/badge.svg" />
  </a>
</p>
<p align="center">
    <a href="#installation">Installation</a>
  • <a href="#usage">Usage</a>
  • <a href="#usage-as-an-xcode-run-script">Usage as an Xcode Run Script</a>
  • <a href="#command-line-api">Command line API</a>
</p>

# LocalizeXIBs

LocalizeXIBs takes the pain out of localizing XIBs and Storyboards, by allowing you to **reference translations directly from Interface Builder**. This means no more dealing with `.strings` files that get out of sync, Object IDs, and missing translations.

**It offers the following benefits**

1. Keep all your translations in one file per language, instead of different `.strings` files throughout your project.
1. Reference your translations directly from Interface Builder, no more dealing with Object ID's.
1. Immediately get a visual overview of what is translated and what not.
1. Compile time checking for missing translations.

The biggest problem with the default way of localizing XIBs and Storyboards, is that you have to reference your views from your translation files by Interface Builder Object IDs. LocalizeXIBs flips this around, and allows you to reference your translations from your IB files. This makes for a much better workflow.

## Installation

```bash
mint install wvteijlingen/localize-xibs
```

## Usage

1. Add all your translations in centralized `.strings` files in your project, for example:
   - `MyProject/Resources/en.lproj/Localizable.strings`
   - `MyProject/Resources/de.lproj/Localizable.strings`.
1. In the Xcode file inspector, configure your XIBs and Storyboards to be localized using "Localizable Strings".
1. Wherever you normally enter text using Interface Builder, you can reference your translation using:
   `t:my_translation_key`.
1. In the root of your project run `localize-xibs`, passing it a list of all your centralized translation files. For example:

   ```bash
   localize-xibs \
     MyProject/Resources/en.lproj/Localizable.strings \
     MyProject/Resources/de.lproj/Localizable.strings
   ```

## Usage as an Xcode Run Script

You can add a Run Script build phase that does the localization for you. That way you can just add translations to your centralized files, and your XIBs and Storyboards will automatically be updated on each build. An added benefit is that it ties in with Xcode, showing you build warnings or errors when you reference a missing translation.

Simply add a `Run Script` phase with the localize-xibs command, optionally using the `--strict` flag. Make sure it is positioned before the "Copy Bundle Resources" phase.

For example:

```bash
localize-xibs --strict \
  MyProject/Resources/en.lproj/Localizable.strings \
  MyProject/Resources/de.lproj/Localizable.strings
```

## Command line API

```
localize-xibs [--strict] [--verbose] [<input-files> ...]
```

- `--strict`: Treat warnings as errors.
- `--verbose`: Display extra information while processing.
