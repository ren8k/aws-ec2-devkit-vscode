#!/bin/bash

set -euo pipefail

# ========================================
# Configuration
# ========================================

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Docker environment options
declare -A DOCKER_ENVS=(
    ["1"]="cpu-uv:CPU環境、uvパッケージマネージャ"
    ["2"]="gpu-uv:GPU環境、uvパッケージマネージャ"
    ["3"]="gpu-sagemaker:GPU環境、SageMaker用"
)

# Files to copy
readonly CONFIG_FILES=(
    ".gitignore"
    ".pre-commit-config.yaml"
    "pyproject.toml"
    "uv.lock"
)

# Project name validation pattern
readonly PROJECT_NAME_PATTERN='^[a-zA-Z0-9_-]+$'

# ========================================
# Utility Functions
# ========================================

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

# ========================================
# Setup Functions
# ========================================

setup_directories() {
    local script_path="${BASH_SOURCE[0]}"
    SCRIPT_DIR="$(cd "$(dirname "$script_path")" && pwd)"
    TEMPLATE_ROOT="$(dirname "$SCRIPT_DIR")"
    PARENT_DIR="$(dirname "$TEMPLATE_ROOT")"
}

# ========================================
# Validation Functions
# ========================================

validate_project_name() {
    local name="$1"

    if [[ -z "$name" ]]; then
        print_error "プロジェクト名は必須です。"
        return 1
    fi

    if [[ ! "$name" =~ $PROJECT_NAME_PATTERN ]]; then
        print_error "プロジェクト名は英数字、ハイフン、アンダースコアのみ使用できます。"
        return 1
    fi

    local project_dir="$PARENT_DIR/$name"
    if [[ -d "$project_dir" ]]; then
        print_error "ディレクトリ '$name' は既に存在します。"
        return 1
    fi

    return 0
}

validate_docker_env_choice() {
    local choice="$1"

    if [[ -n "${DOCKER_ENVS[$choice]:-}" ]]; then
        return 0
    else
        print_error "1, 2, または 3 を選択してください。"
        return 1
    fi
}

# ========================================
# Input Functions
# ========================================

prompt_project_name() {
    local project_name

    while true; do
        echo
        read -r -p "プロジェクト名を入力してください: " project_name

        if validate_project_name "$project_name"; then
            PROJECT_NAME="$project_name"
            PROJECT_DIR="$PARENT_DIR/$project_name"
            break
        fi
    done
}

prompt_docker_environment() {
    echo
    print_info "使用するDocker環境を選択してください:"

    local i
    for i in "${!DOCKER_ENVS[@]}"; do
        local env_info="${DOCKER_ENVS[$i]}"
        local env_name="${env_info%%:*}"
        local env_desc="${env_info#*:}"
        echo "$i) $env_name ($env_desc)"
    done | sort -n

    local choice
    while true; do
        read -r -p "選択 (1-3): " choice

        if validate_docker_env_choice "$choice"; then
            DOCKER_ENV="${DOCKER_ENVS[$choice]%%:*}"
            break
        fi
    done
}

confirm_settings() {
    print_info "選択された設定:"
    echo "  プロジェクト名: $PROJECT_NAME"
    echo "  Docker環境: $DOCKER_ENV"
    echo

    local reply
    read -r -p "この設定で続行しますか？ (y/N): " reply

    if [[ ! $reply =~ ^[Yy]$ ]]; then
        print_info "キャンセルしました。"
        return 1
    fi

    return 0
}

# ========================================
# Project Creation Functions
# ========================================

create_project_directory() {
    print_info "プロジェクトディレクトリを作成中..."

    if ! mkdir -p "$PROJECT_DIR"; then
        print_error "プロジェクトディレクトリの作成に失敗しました。"
        return 1
    fi

    return 0
}

copy_template_files() {
    print_info "必要なファイルをコピー中..."

    local error_occurred=false

    # Copy .devcontainer directory
    if ! cp -r "$TEMPLATE_ROOT/.devcontainer/$DOCKER_ENV" "$PROJECT_DIR/.devcontainer"; then
        print_error ".devcontainerディレクトリのコピーに失敗しました。"
        error_occurred=true
    fi

    # Copy src directory
    if ! cp -r "$TEMPLATE_ROOT/src" "$PROJECT_DIR/"; then
        print_error "srcディレクトリのコピーに失敗しました。"
        error_occurred=true
    fi

    # Copy configuration files
    local file
    for file in "${CONFIG_FILES[@]}"; do
        if ! cp "$TEMPLATE_ROOT/$file" "$PROJECT_DIR/"; then
            print_error "$file のコピーに失敗しました。"
            error_occurred=true
        fi
    done

    # Create README.md
    if ! echo "# $PROJECT_NAME" > "$PROJECT_DIR/README.md"; then
        print_error "README.mdの作成に失敗しました。"
        error_occurred=true
    fi

    if [[ "$error_occurred" == "true" ]]; then
        return 1
    fi

    return 0
}

update_project_files() {
    print_info "ファイルの内容を更新中..."

    local error_occurred=false

    # Update devcontainer.json name
    if ! sed -i "s/\"name\": \"$DOCKER_ENV\"/\"name\": \"$PROJECT_NAME\"/" \
        "$PROJECT_DIR/.devcontainer/devcontainer.json"; then
        print_error "devcontainer.jsonの更新に失敗しました。"
        error_occurred=true
    fi

    # Update pyproject.toml name
    if ! sed -i "s/name = \"app\"/name = \"$PROJECT_NAME\"/" \
        "$PROJECT_DIR/pyproject.toml"; then
        print_error "pyproject.tomlの更新に失敗しました。"
        error_occurred=true
    fi

    # Update uv.lock name
    if ! sed -i "s/name = \"app\"/name = \"$PROJECT_NAME\"/" \
        "$PROJECT_DIR/uv.lock"; then
        print_error "uv.lockの更新に失敗しました。"
        error_occurred=true
    fi

    if [[ "$error_occurred" == "true" ]]; then
        return 1
    fi

    return 0
}

initialize_git_repository() {
    print_info "Gitリポジトリを初期化中..."

    if ! (cd "$PROJECT_DIR" && git init); then
        print_error "Gitリポジトリの初期化に失敗しました。"
        return 1
    fi

    return 0
}

cleanup_on_error() {
    if [[ -d "$PROJECT_DIR" ]]; then
        print_warning "エラーが発生したため、作成されたディレクトリを削除します..."
        rm -rf "$PROJECT_DIR"
    fi
}

show_completion_message() {
    print_success "プロジェクト '$PROJECT_NAME' が正常に作成されました！"
    print_info "プロジェクトディレクトリ: $PROJECT_DIR"
    echo
    print_info "次のステップ:"
    echo "1. cd $PROJECT_DIR"
    echo "2. VS Code でディレクトリを開く"
    echo "3. Dev Container でコンテナを起動する"
    echo "4. 開発を開始！"
}

# ========================================
# Main Function
# ========================================

main() {
    # Setup environment
    setup_directories

    # Show header
    print_info "AWS EC2 DevKit Project Template Generator"
    echo "=========================================="

    # Get user inputs
    prompt_project_name
    prompt_docker_environment

    # Confirm settings
    if ! confirm_settings; then
        exit 0
    fi

    # Create project with error handling
    {
        create_project_directory &&
        copy_template_files &&
        update_project_files &&
        initialize_git_repository
    } || {
        print_error "プロジェクトの作成中にエラーが発生しました。"
        cleanup_on_error
        exit 1
    }

    # Show completion message
    show_completion_message
}

# ========================================
# Script Entry Point
# ========================================

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
