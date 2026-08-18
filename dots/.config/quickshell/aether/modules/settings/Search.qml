import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {
    title: Translation.tr("Search")

    ConfigSwitch {
      title: Translation.tr("Use Levenshtein distance-based algorithm instead of fuzzy")
      checked: Config.options.search.sloppy
      onCheckedChanged: {
        Config.options.search.sloppy = checked;
      }
      StyledToolTip {
        text: Translation.tr("Could be better if you make a ton of typos,\nbut results can be weird and might not work with acronyms\n(e.g. \"GIMP\" might not give you the paint program)")
      }
    }

    ConfigInput {
      title: Translation.tr("Web search")
      description: Translation.tr("The search engine URL to open when running a web search from the launcher")
      placeholderText: Translation.tr("Base URL")
      text: Config.options.search.engineBaseUrl
      inputWidth: 300
      onTextChanged: {
        Config.options.search.engineBaseUrl = text;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Prefixes")

    ConfigInput {
      title: Translation.tr("Action")
      description: Translation.tr("Prefix that triggers action results (e.g. shutdown, lock, screenshot) in the launcher")
      placeholderText: Translation.tr("Action")
      text: Config.options.search.prefix.action
      onTextChanged: {
        Config.options.search.prefix.action = text;
      }
    }

    ConfigInput {
      title: Translation.tr("Clipboard")
      description: Translation.tr("Prefix that searches your clipboard history in the launcher")
      placeholderText: Translation.tr("Clipboard")
      text: Config.options.search.prefix.clipboard
      onTextChanged: {
        Config.options.search.prefix.clipboard = text;
      }
    }

    ConfigInput {
      title: Translation.tr("Math")
      description: Translation.tr("Prefix that evaluates the following text as a math expression in the launcher")
      placeholderText: Translation.tr("Math")
      text: Config.options.search.prefix.math
      onTextChanged: {
        Config.options.search.prefix.math = text;
      }
    }

    ConfigInput {
      title: Translation.tr("Shell command")
      description: Translation.tr("Prefix that runs the following text as a shell command from the launcher")
      placeholderText: Translation.tr("Shell command")
      text: Config.options.search.prefix.shellCommand
      onTextChanged: {
        Config.options.search.prefix.shellCommand = text;
      }
    }

    ConfigInput {
      title: Translation.tr("Web search")
      description: Translation.tr("Prefix that forces the query to be treated as a web search in the launcher")
      placeholderText: Translation.tr("Web search")
      text: Config.options.search.prefix.webSearch
      onTextChanged: {
        Config.options.search.prefix.webSearch = text;
      }
    }
  }
}
