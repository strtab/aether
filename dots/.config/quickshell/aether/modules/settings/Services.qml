import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
  forceWidth: true

  ContentSection {
    title: Translation.tr("Music Recognition")

    ConfigSpinBox {
      title: Translation.tr("Total duration timeout (s)")
      value: Config.options.musicRecognition.timeout
      from: 10
      to: 100
      stepSize: 2
      onValueChanged: {
        Config.options.musicRecognition.timeout = value;
      }
    }
    ConfigSpinBox {
      title: Translation.tr("Polling interval (s)")
      value: Config.options.musicRecognition.interval
      from: 2
      to: 10
      stepSize: 1
      onValueChanged: {
        Config.options.musicRecognition.interval = value;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Networking")

    Input {
      Layout.fillWidth: true
      placeholderText: Translation.tr("User agent (for services that require it)")
      text: Config.options.networking.userAgent
      wrapMode: TextEdit.Wrap
      onTextChanged: {
        Config.options.networking.userAgent = text;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Resources")

    ConfigSpinBox {
      title: Translation.tr("Polling interval (ms)")
      value: Config.options.resources.updateInterval
      from: 100
      to: 10000
      stepSize: 100
      onValueChanged: {
        Config.options.resources.updateInterval = value;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Save paths")

    Input {
      Layout.fillWidth: true
      placeholderText: Translation.tr("Video Recording Path")
      text: Config.options.screenRecord.savePath
      wrapMode: TextEdit.Wrap
      onTextChanged: {
        Config.options.screenRecord.savePath = text;
      }
    }

    Input {
      Layout.fillWidth: true
      placeholderText: Translation.tr("Screenshot Path (leave empty to just copy)")
      text: Config.options.screenSnip.savePath
      wrapMode: TextEdit.Wrap
      onTextChanged: {
        Config.options.screenSnip.savePath = text;
      }
    }
  }

  ContentSection {
    title: Translation.tr("Weather")
    ConfigSwitch {
      title: Translation.tr("Enable GPS based location")
      checked: Config.options.bar.weather.enableGPS
      onCheckedChanged: {
        Config.options.bar.weather.enableGPS = checked;
      }
    }
    ConfigSwitch {
      title: Translation.tr("Fahrenheit unit")
      description:  Translation.tr("It may take a few seconds to update")
      checked: Config.options.bar.weather.useUSCS
      onCheckedChanged: {
        Config.options.bar.weather.useUSCS = checked;
      }
    }

    Input {
      Layout.fillWidth: true
      placeholderText: Translation.tr("City name")
      text: Config.options.bar.weather.city
      wrapMode: TextEdit.Wrap
      onTextChanged: {
        Config.options.bar.weather.city = text;
      }
    }
    ConfigSpinBox {
      title: Translation.tr("Polling interval (m)")
      value: Config.options.bar.weather.fetchInterval
      from: 5
      to: 50
      stepSize: 5
      onValueChanged: {
        Config.options.bar.weather.fetchInterval = value;
      }
    }
  }
}
