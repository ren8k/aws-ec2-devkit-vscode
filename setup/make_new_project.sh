#!/bin/bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the directory where this script is located (setup directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Get the template root directory (parent of setup)
TEMPLATE_ROOT="$(dirname "$SCRIPT_DIR")"
# Get the parent directory where new projects will be created
PARENT_DIR="$(dirname "$TEMPLATE_ROOT")"

print_info "AWS EC2 DevKit Project Template Generator"
echo "=========================================="

# Interactive prompt for project name
while true; do
    echo
    read -r -p "プロジェクト名を入力してください: " PROJECT_NAME
    
    if [[ -z "$PROJECT_NAME" ]]; then
        print_error "プロジェクト名は必須です。"
        continue
    fi
    
    # Check if directory already exists
    PROJECT_DIR="$PARENT_DIR/$PROJECT_NAME"
    if [[ -d "$PROJECT_DIR" ]]; then
        print_error "ディレクトリ '$PROJECT_NAME' は既に存在します。"
        continue
    fi
    
    # Validate project name (allow alphanumeric, hyphens, underscores)
    if [[ ! "$PROJECT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "プロジェクト名は英数字、ハイフン、アンダースコアのみ使用できます。"
        continue
    fi
    
    break
done

# Interactive prompt for Docker environment
echo
print_info "使用するDocker環境を選択してください:"
echo "1) cpu-uv (CPU環境、uvパッケージマネージャ)"
echo "2) gpu-uv (GPU環境、uvパッケージマネージャ)"
echo "3) gpu-sagemaker (GPU環境、SageMaker用)"

while true; do
    read -r -p "選択 (1-3): " ENV_CHOICE
    
    case $ENV_CHOICE in
        1)
            DOCKER_ENV="cpu-uv"
            break
            ;;
        2)
            DOCKER_ENV="gpu-uv"
            break
            ;;
        3)
            DOCKER_ENV="gpu-sagemaker"
            break
            ;;
        *)
            print_error "1, 2, または 3 を選択してください。"
            ;;
    esac
done

print_info "選択された設定:"
echo "  プロジェクト名: $PROJECT_NAME"
echo "  Docker環境: $DOCKER_ENV"
echo

# Confirm before proceeding
read -p "この設定で続行しますか？ (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_info "キャンセルしました。"
    exit 0
fi

print_info "プロジェクトディレクトリを作成中..."

# Create project directory
mkdir -p "$PROJECT_DIR"

# Copy required files and directories
print_info "必要なファイルをコピー中..."

# Copy .devcontainer directory (selected environment only)
cp -r "$TEMPLATE_ROOT/.devcontainer/$DOCKER_ENV" "$PROJECT_DIR/.devcontainer"

# Copy src directory
cp -r "$TEMPLATE_ROOT/src" "$PROJECT_DIR/"

# Copy configuration files
cp "$TEMPLATE_ROOT/.gitignore" "$PROJECT_DIR/"
cp "$TEMPLATE_ROOT/.pre-commit-config.yaml" "$PROJECT_DIR/"
cp "$TEMPLATE_ROOT/pyproject.toml" "$PROJECT_DIR/"
cp "$TEMPLATE_ROOT/uv.lock" "$PROJECT_DIR/"

# Create README.md
echo "# $PROJECT_NAME" > "$PROJECT_DIR/README.md"

print_info "ファイルの内容を更新中..."

# Update devcontainer.json name
sed -i "s/\"name\": \"$DOCKER_ENV\"/\"name\": \"$PROJECT_NAME\"/" "$PROJECT_DIR/.devcontainer/devcontainer.json"

# Update pyproject.toml name
sed -i "s/name = \"app\"/name = \"$PROJECT_NAME\"/" "$PROJECT_DIR/pyproject.toml"

# Note: uv.lock doesn't need to be updated as it will be regenerated when the project is built

print_success "プロジェクト '$PROJECT_NAME' が正常に作成されました！"
print_info "プロジェクトディレクトリ: $PROJECT_DIR"
echo
print_info "次のステップ:"
echo "1. cd $PROJECT_DIR"
echo "2. VS Code でディレクトリを開く"
echo "3. Dev Container で再開する"
echo "4. 開発を開始！"