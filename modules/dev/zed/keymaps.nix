{
  config,
  lib,
  username,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.modules.dev.zed;
in
{
  config = mkIf cfg.enable {
    home-manager.users.${username}.programs.zed-editor = {
      userKeymaps = [
        {
          bindings = {
            home = "menu::SelectFirst";
            pageup = "menu::SelectFirst";
            end = "menu::SelectLast";
            pagedown = "menu::SelectLast";
            down = "menu::SelectNext";
            up = "menu::SelectPrevious";
            enter = "menu::Confirm";
            ctrl-enter = "menu::SecondaryConfirm";
            ctrl-c = "menu::Cancel";
            escape = "menu::Cancel";
            alt-enter = [
              "picker::ConfirmInput"
              {
                secondary = false;
              }
            ];
            ctrl-alt-enter = [
              "picker::ConfirmInput"
              {
                secondary = true;
              }
            ];
            "ctrl-=" = [
              "zed::IncreaseBufferFontSize"
              {
                persist = false;
              }
            ];
            "ctrl-+" = [
              "zed::IncreaseBufferFontSize"
              {
                persist = false;
              }
            ];
            ctrl-- = [
              "zed::DecreaseBufferFontSize"
              {
                persist = false;
              }
            ];
            ctrl-0 = [
              "zed::ResetBufferFontSize"
              {
                persist = false;
              }
            ];
            ctrl-alt-s = "zed::OpenSettings";
            shift-f10 = [
              "task::Rerun"
              {
                reevaluate_context = false;
              }
            ];
            alt-shift-f10 = "task::Spawn";
            shift-f9 = [
              "debugger::Rerun"
              {
                reevaluate_context = false;
              }
            ];
            alt-shift-f9 = "debugger::Start";
            ctrl-f2 = "debugger::Stop";
            f9 = "debugger::Continue";
            f6 = "debugger::Pause";
            f7 = "debugger::StepInto";
            f8 = "debugger::StepOver";
            shift-f8 = "debugger::StepOut";
            ctrl-o = "workspace::Open";
            ctrl-shift-c = "workspace::CopyPath";
          };
        }
        {
          context = "Picker || menu";
          bindings = {
            up = "menu::SelectPrevious";
            down = "menu::SelectNext";
            tab = "picker::ConfirmCompletion";
            shift-backspace = "editor::DeleteToPreviousWordStart";
            ctrl-backspace = "editor::DeleteToPreviousWordStart";
          };
        }
        {
          context = "Editor";
          bindings = {
            escape = "editor::Cancel";
            backspace = "editor::Backspace";
            ctrl-backspace = [
              "editor::DeleteToPreviousWordStart"
              {
                ignore_newlines = false;
                ignore_brackets = false;
              }
            ];
            delete = "editor::Delete";
            ctrl-delete = [
              "editor::DeleteToNextWordEnd"
              {
                ignore_newlines = false;
                ignore_brackets = false;
              }
            ];
            tab = "editor::Tab";
            shift-tab = "editor::Backtab";
            up = "editor::MoveUp";
            shift-up = "editor::SelectUp";
            down = "editor::MoveDown";
            shift-down = "editor::SelectDown";
            left = "editor::MoveLeft";
            shift-left = "editor::SelectLeft";
            ctrl-left = "editor::MoveToPreviousWordStart";
            ctrl-shift-left = "editor::SelectToPreviousWordStart";
            right = "editor::MoveRight";
            shift-right = "editor::SelectRight";
            ctrl-right = "editor::MoveToNextWordEnd";
            ctrl-shift-right = "editor::SelectToNextWordEnd";
            pageup = "editor::MovePageUp";
            shift-pageup = "editor::SelectPageUp";
            pagedown = "editor::MovePageDown";
            shift-pagedown = "editor::SelectPageDown";
            home = [
              "editor::MoveToBeginningOfLine"
              {
                stop_at_soft_wraps = true;
                stop_at_indent = true;
              }
            ];
            ctrl-home = "editor::MoveToBeginning";
            shift-home = [
              "editor::SelectToBeginningOfLine"
              {
                stop_at_soft_wraps = true;
                stop_at_indent = true;
              }
            ];
            ctrl-shift-home = "editor::SelectToBeginning";
            end = [
              "editor::MoveToEndOfLine"
              {
                stop_at_soft_wraps = true;
              }
            ];
            ctrl-end = "editor::MoveToEnd";
            shift-end = [
              "editor::SelectToEndOfLine"
              {
                stop_at_soft_wraps = true;
              }
            ];
            ctrl-shift-end = "editor::SelectToEnd";
            ctrl-c = "editor::Copy";
            ctrl-v = "editor::Paste";
            ctrl-x = "editor::Cut";
            ctrl-z = "editor::Undo";
            ctrl-shift-z = "editor::Redo";
            ctrl-a = "editor::SelectAll";
            ctrl-l = "editor::SelectLine";
            ctrl-space = "editor::ShowCompletions";
            "ctrl-." = "editor::ToggleFold";
            "ctrl->" = "editor::ToggleFoldRecursive";
            ctrl-alt-l = "editor::Format";
            ctrl-alt-o = "editor::OrganizeImports";
            ctrl-p = "editor::ShowSignatureHelp";
            ctrl-f8 = "editor::ToggleBreakpoint";
            ctrl-shift-f8 = "editor::EditLogBreakpoint";
            "ctrl-/" = [
              "editor::ToggleComments"
              {
                advance_downwards = true;
              }
            ];
            alt-j = [
              "editor::SelectNext"
              {
                replace_newest = false;
              }
            ];
            alt-shift-j = [
              "editor::SelectPrevious"
              {
                replace_newest = false;
              }
            ];
            ctrl-shift-alt-j = "editor::SelectAllMatches";
            ctrl-shift-j = "editor::JoinLines";
            ctrl-d = "editor::DuplicateSelection";
            ctrl-m = "editor::ScrollCursorCenter";
            ctrl-pagedown = "editor::MovePageDown";
            ctrl-pageup = "editor::MovePageUp";
            ctrl-alt-enter = "editor::NewlineAbove";
            ctrl-shift-w = "editor::SelectSmallerSyntaxNode";
            shift-f6 = "editor::Rename";
            "alt-&" = "editor::FindAllReferences";
            ctrl-b = "editor::GoToDefinition";
            ctrl-alt-b = "editor::GoToImplementation";
            ctrl-shift-b = "editor::GoToTypeDefinition";
            ctrl-alt-shift-b = "editor::GoToTypeDefinitionSplit";
            f2 = "editor::GoToDiagnostic";
            shift-f2 = "editor::GoToPreviousDiagnostic";
            ctrl-shift-u = "editor::ToggleCase";
            f3 = "search::SelectNextMatch";
            shift-f3 = "search::SelectPreviousMatch";
            ctrl-f4 = "pane::CloseActiveItem";
            ctrl-shift-m = "editor::MoveToEnclosingBracket";
            ctrl-y = "editor::DeleteLine";
            shift-alt-g = "editor::SplitSelectionIntoLines";
            ctrl-shift-i = "editor::GoToDefinitionSplit";
          };
        }
        {
          context = "Editor && mode == full";
          bindings = {
            enter = "editor::Newline";
            shift-enter = "editor::Newline";
            ctrl-enter = "editor::NewlineBelow";
            ctrl-shift-enter = "editor::NewlineAbove";
            ctrl-f = "buffer_search::Deploy";
            ctrl-r = "buffer_search::DeployReplace";
            ctrl-q = "editor::Hover";
            ctrl-p = "editor::ShowSignatureHelp";
            ctrl-g = "go_to_line::Toggle";
            ctrl-f12 = "outline::Toggle";
            alt-enter = "editor::ToggleCodeActions";
            ctrl-space = "editor::ShowCompletions";
            ctrl-w = "editor::SelectLargerSyntaxNode";
          };
        }
        {
          context = "Editor && mode == auto_height";
          bindings = {
            ctrl-enter = "editor::Newline";
            shift-enter = "editor::Newline";
            ctrl-shift-enter = "editor::NewlineBelow";
          };
        }
        {
          context = "Editor && showing_completions";
          bindings = {
            enter = "editor::ConfirmCompletion";
            shift-enter = "editor::ConfirmCompletionReplace";
            tab = "editor::ComposeCompletion";
          };
        }
        {
          context = "Editor && renaming";
          bindings = {
            enter = "editor::ConfirmRename";
          };
        }
        {
          context = "Editor && showing_code_actions";
          bindings = {
            enter = "editor::ConfirmCodeAction";
          };
        }
        {
          context = "Editor && (showing_code_actions || showing_completions)";
          bindings = {
            up = "editor::ContextMenuPrevious";
            down = "editor::ContextMenuNext";
            pageup = "editor::ContextMenuFirst";
            pagedown = "editor::ContextMenuLast";
          };
        }
        {
          context = "Editor && showing_signature_help && !showing_completions";
          bindings = {
            up = "editor::SignatureHelpPrevious";
            down = "editor::SignatureHelpNext";
          };
        }
        {
          context = "Markdown";
          bindings = {
            ctrl-c = "markdown::Copy";
          };
        }
        {
          context = "BufferSearchBar";
          bindings = {
            escape = "buffer_search::Dismiss";
            enter = "search::SelectNextMatch";
            shift-enter = "search::SelectPreviousMatch";
            tab = "buffer_search::FocusEditor";
            alt-enter = "search::SelectAllMatches";
            ctrl-f = "search::FocusSearch";
            ctrl-r = "search::ToggleReplace";
          };
        }
        {
          context = "BufferSearchBar || ProjectSearchBar";
          bindings = {
            alt-c = "search::ToggleCaseSensitive";
            alt-e = "search::ToggleSelection";
            alt-x = "search::ToggleRegex";
            alt-w = "search::ToggleWholeWord";
          };
        }
        {
          context = "BufferSearchBar > Editor";
          bindings = {
            up = "search::SelectNextMatch";
            down = "search::SelectPreviousMatch";
          };
        }
        {
          context = "BufferSearchBar && in_replace > Editor";
          bindings = {
            enter = "search::ReplaceNext";
          };
        }
        {
          context = "Pane";
          bindings = {
            alt-0 = "git_panel::ToggleFocus";
            alt-1 = "project_panel::ToggleFocus";
            alt-5 = "debug_panel::ToggleFocus";
            alt-6 = "diagnostics::Deploy";
            alt-7 = "outline_panel::ToggleFocus";
            alt-9 = "git_panel::ToggleFocus";
            alt-left = "pane::ActivatePreviousItem";
            alt-right = "pane::ActivateNextItem";
          };
        }
        {
          context = "Workspace";
          bindings = {
            ctrl-k = "git_panel::ToggleFocus";
            ctrl-s = "workspace::SaveAll";
            "shift shift" = "command_palette::Toggle";
            ctrl-shift-f = "pane::DeploySearch";
            ctrl-shift-r = [
              "pane::DeploySearch"
              {
                replace_enabled = true;
              }
            ];
            ctrl-shift-a = "command_palette::Toggle";
            ctrl-shift-n = "file_finder::Toggle";
            ctrl-alt-shift-n = "project_symbols::Toggle";
            ctrl-shift-f12 = "workspace::ToggleAllDocks";
            alt-0 = "git_panel::ToggleFocus";
            alt-1 = "project_panel::ToggleFocus";
            alt-5 = "debug_panel::ToggleFocus";
            alt-6 = "diagnostics::Deploy";
            alt-7 = "outline_panel::ToggleFocus";
            alt-9 = "git_panel::ToggleFocus";
            alt-f8 = "debugger::EvaluateSelectedText";
            alt-f9 = "debugger::RunToCursor";
            shift-alt-8 = "debugger::EvaluateSelectedText";
            shift-alt-9 = "debugger::RunToCursor";
            ctrl-shift-alt-insert = "workspace::NewFile";
          };
        }
        {
          context = "Workspace || Editor";
          bindings = {
            alt-f12 = "terminal_panel::Toggle";
            ctrl-shift-k = "git::Push";
          };
        }
        {
          context = "GitPanel";
          bindings = {
            alt-0 = "workspace::CloseActiveDock";
            alt-9 = "workspace::CloseActiveDock";
          };
        }
        {
          context = "DebugPanel";
          bindings = {
            alt-5 = "workspace::CloseActiveDock";
          };
        }
        {
          context = "Diagnostics";
          bindings = {
            alt-6 = "pane::CloseActiveItem";
            ctrl-r = "diagnostics::ToggleDiagnosticsRefresh";
          };
        }
        {
          context = "OutlinePanel";
          bindings = {
            alt-7 = "workspace::CloseActiveDock";
          };
        }
        {
          context = "Dock || Workspace || OutlinePanel || ProjectPanel || CollabPanel || (Editor && mode == auto_height)";
          bindings = {
            escape = "editor::ToggleFocus";
            shift-escape = "workspace::CloseActiveDock";
          };
        }
        {
          context = "Terminal";
          bindings = {
            ctrl-c = [
              "terminal::SendKeystroke"
              "ctrl-c"
            ];
            ctrl-shift-c = "terminal::Copy";
            ctrl-shift-v = "terminal::Paste";
            ctrl-shift-t = "workspace::NewTerminal";
            alt-f12 = "workspace::CloseActiveDock";
            up = [
              "terminal::SendKeystroke"
              "up"
            ];
            ctrl-up = "terminal::ScrollLineUp";
            shift-up = "terminal::ScrollLineUp";
            down = [
              "terminal::SendKeystroke"
              "down"
            ];
            ctrl-down = "terminal::ScrollLineDown";
            shift-down = "terminal::ScrollLineDown";
            pageup = [
              "terminal::SendKeystroke"
              "pageup"
            ];
            shift-pageup = "terminal::ScrollPageUp";
            pagedown = [
              "terminal::SendKeystroke"
              "pagedown"
            ];
            shift-pagedown = "terminal::ScrollPageDown";
            shift-home = "terminal::ScrollToTop";
            shift-end = "terminal::ScrollToBottom";
            escape = [
              "terminal::SendKeystroke"
              "escape"
            ];
            enter = [
              "terminal::SendKeystroke"
              "enter"
            ];
            ctrl-shift-a = "editor::SelectAll";
          };
        }
        {
          context = "ProjectPanel";
          bindings = {
            alt-1 = "workspace::CloseActiveDock";
            ctrl-c = "project_panel::Copy";
            ctrl-d = "project_panel::CompareMarkedFiles";
            ctrl-v = "project_panel::Paste";
            ctrl-x = "project_panel::Cut";
            enter = "project_panel::Open";
            ctrl-shift-f = "project_panel::NewSearchInDirectory";
            delete = [
              "project_panel::Trash"
              {
                skip_prompt = false;
              }
            ];
            shift-f6 = "project_panel::Rename";
            f2 = "project_panel::Rename";
          };
        }
        {
          context = "SettingsWindow";
          bindings = {
            escape = "workspace::CloseWindow";
            ctrl-w = "workspace::CloseWindow";
            ctrl-f = "search::FocusSearch";
            left = "settings_editor::ToggleFocusNav";
          };
        }
        {
          context = "SettingsWindow > NavigationMenu";
          use_key_equivalents = true;
          bindings = {
            up = "settings_editor::FocusPreviousNavEntry";
            shift-tab = "settings_editor::FocusPreviousNavEntry";
            down = "settings_editor::FocusNextNavEntry";
            tab = "settings_editor::FocusNextNavEntry";
            right = "settings_editor::ExpandNavEntry";
            left = "settings_editor::CollapseNavEntry";
            pageup = "settings_editor::FocusPreviousRootNavEntry";
            pagedown = "settings_editor::FocusNextRootNavEntry";
            home = "settings_editor::FocusFirstNavEntry";
            end = "settings_editor::FocusLastNavEntry";
          };
        }
        {
          context = "StashList || (StashList > Picker > Editor)";
          bindings = {
            delete = "stash_picker::DropStashItem";
            ctrl-shift-v = "stash_picker::ShowStashItem";
          };
        }
        {
          context = "GitBranchSelector || (GitBranchSelector > Picker > Editor)";
          use_key_equivalents = true;
          bindings = {
            delete = "branch_picker::DeleteBranch";
            ctrl-shift-i = "branch_picker::FilterRemotes";
          };
        }
        {
          context = "KeybindEditorModal > Editor";
          use_key_equivalents = true;
          bindings = {
            up = "menu::SelectPrevious";
            down = "menu::SelectNext";
          };
        }
        {
          context = "KeybindEditorModal";
          use_key_equivalents = true;
          bindings = {
            ctrl-enter = "menu::Confirm";
            escape = "menu::Cancel";
          };
        }
        {
          context = "KeystrokeInput";
          use_key_equivalents = true;
          bindings = {
            enter = "keystroke_input::StartRecording";
            "escape escape escape" = "keystroke_input::StopRecording";
            delete = "keystroke_input::ClearKeystrokes";
          };
        }
        {
          context = "KeymapEditor";
          use_key_equivalents = true;
          bindings = {
            ctrl-f = "search::FocusSearch";
            alt-ctrl-f = "keymap_editor::ToggleKeystrokeSearch";
            alt-c = "keymap_editor::ToggleConflictFilter";
            enter = "keymap_editor::EditBinding";
            alt-enter = "keymap_editor::CreateBinding";
            ctrl-c = "keymap_editor::CopyAction";
            ctrl-shift-c = "keymap_editor::CopyContext";
            ctrl-t = "keymap_editor::ShowMatchingKeybinds";
          };
        }
        {
          context = "InvalidBuffer";
          use_key_equivalents = true;
          bindings = {
            ctrl-shift-enter = "workspace::OpenWithSystem";
          };
        }
        {
          context = "DebugConsole > Editor";
          use_key_equivalents = true;
          bindings = {
            enter = "menu::Confirm";
            alt-enter = "console::WatchExpression";
          };
        }
        {
          context = "ConfigureContextServerModal > Editor";
          bindings = {
            escape = "menu::Cancel";
            enter = "editor::Newline";
            ctrl-enter = "menu::Confirm";
          };
        }
      ];
    };
  };
}
