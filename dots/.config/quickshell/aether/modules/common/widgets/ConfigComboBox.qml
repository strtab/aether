import QtQuick
import qs.modules.common
import qs.modules.common.widgets

ContentSubsection {
  id: root

  // Combo box appearance
  property string buttonIcon: ""
  property string textRole: "displayName"
  // Key inside each model item that holds the actual value (as opposed to the display label)
  property string valueRole: "value"

  // model items are expected to look like: { [textRole]: "Label", [valueRole]: <value> }
  property var model: []

  // Currently selected value. Bind this to the config/source of truth from the outside,
  // e.g. `value: Config.options.language.ui` — this component never writes to it directly.
  property var value: undefined

  // Emitted when the user picks a different item; the caller is responsible
  // for actually persisting it (e.g. `onSelected: v => Config.options.language.ui = v`).
  signal selected(var newValue)

  StyledComboBox {
    id: comboBox
    buttonIcon: root.buttonIcon
    textRole: root.textRole
    model: root.model

    currentIndex: {
      const index = root.model.findIndex(item => item[root.valueRole] === root.value);
      return index !== -1 ? index : 0;
    }

    onActivated: index => {
      root.selected(root.model[index][root.valueRole]);
    }
  }
}
