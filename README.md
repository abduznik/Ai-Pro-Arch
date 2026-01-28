# Abduznik's AI Project Architect

A powerful, multi-modal AI tool designed to integrate seamlessly into your DevOps workflow. It handles project scaffolding, intelligent code patching, and architectural explanations using Gemini models.

## Features

- **Project Scaffolding (Init):** Generates and executes shell commands to set up new projects based on natural language descriptions.
- **Smart Fix (Fix):** Analyzes errors and file content to apply precise code patches in place.
- **Code Explanation (Explain):** Provides concise, technical explanations for complex concepts or code snippets.
- **Resilient Architecture:** Automatically falls back from Gemini 3 to Flash models if quotas are hit or errors occur.
- **Docker Ready:** Fully compatible with both the native Node.js CLI and the custom Python shim used in the AI Stack Manager.

## Prerequisites

1. **PowerShell**
2. **Gemini CLI**
   - Native: `npm install -g @google/gemini-cli`
   - Or Docker Shim: Ensure `gemini` command is in PATH.

## Installation

Run this command in PowerShell to install:

```powershell
irm https://raw.githubusercontent.com/abduznik/ai-pro-arch/main/setup.ps1 | iex
```

This will:
1. Download the tool to `$HOME\AI-Pro-Arch`.
2. Add it to your PowerShell profile.
3. Enable the `ai-pro-arch` command immediately.

## Usage

### 1. Initialize a Project
Ask the AI to set up a new project structure.
```powershell
ai-pro-arch -Mode Init -Input "Create a React app with Vite named 'dashboard'"
```

### 2. Fix a File
Provide an error message or request, and target a specific file to patch.
```powershell
ai-pro-arch -Mode Fix -Input "Fix the null pointer exception in the main loop" -File ".\src\main.ts"
```
*Note: This creates a backup `.bak` file before applying changes.*

### 3. Explain Code
Get a quick technical explanation.
```powershell
ai-pro-arch -Mode Explain -Input "How does the Python Global Interpreter Lock affect threading?"
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
