#!/bin/bash

# ホスト側のディレクトリを作成し、権限を設定するスクリプト
# 実行前に: chmod +x setup-dirs.sh
# 実行: sudo ./setup-dirs.sh

# UID/GIDの設定（.envファイルと同じ値を使用）
USER_ID=9001
GROUP_ID=9001

echo "ComfyUI用のディレクトリを作成しています..."

# モデル用ディレクトリの作成
mkdir -p /srv/ai-models/comfyui/{checkpoints,vae,loras,embeddings,controlnet,clip,clip_vision,style_models,diffusion_models,gligen,upscale_models,hypernetworks,vae_approx,text_encoders}

# ComfyUI作業用ディレクトリの作成
mkdir -p /srv/comfyui/{custom_nodes,input,output,temp,user}

# 権限の設定（UID/GID 9001に設定）
echo "権限を設定しています..."
chown -R ${USER_ID}:${GROUP_ID} /srv/ai-models/comfyui
chown -R ${USER_ID}:${GROUP_ID} /srv/comfyui

# 書き込み権限を付与
chmod -R 755 /srv/ai-models/comfyui
chmod -R 755 /srv/comfyui

# 特に書き込みが必要なディレクトリには追加権限を付与
chmod 777 /srv/comfyui/output
chmod 777 /srv/comfyui/input
chmod 777 /srv/comfyui/temp
chmod 777 /srv/comfyui/user

echo "ディレクトリの設定が完了しました！"
echo ""
echo "ディレクトリ構造:"
echo "  /srv/ai-models/comfyui/ - モデルファイル用"
echo "  /srv/comfyui/ - 作業ファイル用"
echo ""
echo "次のステップ:"
echo "  1. docker-compose build"
echo "  2. docker-compose up -d"
