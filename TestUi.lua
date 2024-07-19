loadstring(game:HttpGet(("https://raw.githubusercontent.com/REDzHUB/LibraryV2/main/redzLib")))()

MakeWindow({
  Hub = {
    Title = "For Black Men",
    Animation = "by : Cobeyxz"
  },
  Key = {
    KeySystem = true,
    Title = "Key System",
    Description = "",
    KeyLink = "",
    Keys = {"TesKey"},
    Notifi = {
      Notifications = true,
      CorrectKey = "Running the Script...",
      Incorrectkey = "The key is incorrect",
      CopyKeyLink = "Copied to Clipboard"
    }
  }
})


MinimizeButton({
  Image = "",
  Size = {40, 40},
  Color = Color3.fromRGB(10, 10, 10),
  Corner = true,
  Stroke = false,
  StrokeColor = Color3.fromRGB(255, 0, 0)
})

local Main = MakeTab({Name = "Main"})



MakeNotifi({
  Title = "Niggaz Dorm",
  Text = "This is a test",
  Time = 5
})

local section = AddSection(Main, {"Test"})


AddButton(Main, {
  Name = "Botton test",
  Callback = function()
    printidentity()
  end
})

local Toggle = AddToggle(Main, {
  Name = "Toggle test",
  Default = false,
  Callback = function(Value)
    
  end
})



local Slider = AddSlider(Main, {
  Name = "Slider test",
  MinValue = 10,
  MaxValue = 100,
  Default = 25,
  Increase = 1,
  Callback = function(Value)
    print(Value)
  end
})

AddKeybind(Main, {
  Name = "Keybind test",
  KeyCode = "E",
  Default = false,
  Callback = function(Value)
    
  end
})


AddTextBox(Main, {
  Name = "TextBox test",
  Default = "Good Morning",
  PlaceholderText = "test",
  ClearText = true,
  Callback = function(Value)
    
  end
})


local Dropdown = AddDropdown(Main, {
  Name = "Dropdown test",
  Options = {"1", "2", "3"},
  Default = "2",
  Callback = function(Value)
    MakeNotifi({
  Title = "Niggaz Dorm",
  Text = (Value),
  Time = 5
})
  end
})



AddColorPicker(Main, {
  Name = "Color picker test",
  Default = Color3.fromRGB(255, 255, 0),
  Callback = function(Value)
    
  end
})

local Label = AddTextLabel(Main, "AutoFarm")

local Paragraph = AddParagraph(Main, {"Paragraph test", "Nigger"})

local Image = AddImageLabel(Main, {
  Name = "Cool Image",
  Image = "rbxassetid://11696689831"
})
