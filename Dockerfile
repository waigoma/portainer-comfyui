# NVIDIA CUDA 13.0 + cuDNN + Ubuntu 24.04をベースイメージとして使用
FROM nvidia/cuda:13.0.0-cudnn-devel-ubuntu24.04

# 環境変数の設定
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV COMFYUI_PORT=8188
ENV USER_ID=1000
ENV GROUP_ID=1000

# 必要なパッケージのインストール
# Ubuntu 24.04対応: 旧パッケージ名から新パッケージ名への移行
# libgl1-mesa-glx → libgl1 + libglx-mesa0
# libegl1-mesa → libegl1
RUN apt-get update && apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    git \
    wget \
    curl \
    libgl1 \
    libglx-mesa0 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    ffmpeg \
    libgbm1 \
    libegl1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Python 3.12をデフォルトに設定
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1 \
    && update-alternatives --install /usr/bin/python python /usr/bin/python3.12 1

# pipの確認（Ubuntu 24.04のpip 24.0は十分新しいのでアップグレードは不要）
# 必要に応じて特定のパッケージ管理ツールをインストール
RUN python3 -m pip --version

# ComfyUIユーザーの作成
RUN groupadd -g ${GROUP_ID} comfyui && \
    useradd -m -u ${USER_ID} -g comfyui -s /bin/bash comfyui

# 作業ディレクトリの設定
WORKDIR /app

# ComfyUIのクローン（公式リポジトリから最新版を取得）
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /app/ComfyUI

# ComfyUI-Managerのインストール（オプション - 便利な管理ツール）
RUN git clone https://github.com/Comfy-Org/ComfyUI-Manager.git /app/ComfyUI/custom_nodes/ComfyUI-Manager

# 必要なディレクトリ構造の作成
RUN mkdir -p /app/ComfyUI/models/checkpoints \
    /app/ComfyUI/models/vae \
    /app/ComfyUI/models/loras \
    /app/ComfyUI/models/embeddings \
    /app/ComfyUI/models/controlnet \
    /app/ComfyUI/models/clip \
    /app/ComfyUI/models/clip_vision \
    /app/ComfyUI/models/style_models \
    /app/ComfyUI/models/diffusion_models \
    /app/ComfyUI/models/gligen \
    /app/ComfyUI/models/upscale_models \
    /app/ComfyUI/models/hypernetworks \
    /app/ComfyUI/models/vae_approx \
    /app/ComfyUI/models/text_encoders \
    /app/ComfyUI/input \
    /app/ComfyUI/output \
    /app/ComfyUI/temp

# PyTorchのインストール（CUDA 12.9 - 最新の安定版、CUDA 13.0と互換性あり）
# CUDA 13.0は後方互換性があるため、12.9のPyTorchを使用
RUN pip install --break-system-packages torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu129

# ComfyUIの依存関係インストール
WORKDIR /app/ComfyUI
RUN pip install --break-system-packages -r requirements.txt

# ComfyUI-Managerの依存関係インストール
RUN if [ -f /app/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt ]; then \
    pip install --break-system-packages -r /app/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt; \
    fi

# 権限の設定
RUN chown -R comfyui:comfyui /app

# ユーザーを切り替え
USER comfyui

# ポートの公開
EXPOSE 8188

# 起動スクリプトの作成
RUN echo '#!/bin/bash\n\
python3 /app/ComfyUI/main.py --listen 0.0.0.0 --port ${COMFYUI_PORT}' > /app/start.sh \
    && chmod +x /app/start.sh

# エントリポイント
ENTRYPOINT ["/app/start.sh"]
