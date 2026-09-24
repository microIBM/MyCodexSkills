"""MiniMax 音色克隆辅助脚本：上传 voices/ 下你自己的录音 -> 克隆 -> 试听验证。

用法（在 web/ 目录下）:
    python clone_voice.py [自定义voice_id]

前提: web/.env 已配置 MINIMAX_API_KEY 和 MINIMAX_GROUP_ID。
注意: 只能上传你本人的声音或已获授权的素材。
"""

import glob
import os
import sys

for _s in (sys.stdout, sys.stderr):
    if _s and hasattr(_s, "reconfigure"):
        _s.reconfigure(encoding="utf-8")

import httpx

from app import config

TEST_TEXT = "兄弟，只做龙头不做杂毛，会空仓的才是祖师爷。"


def die(msg: str):
    print(f"[错误] {msg}")
    sys.exit(1)


def main():
    if not config.MINIMAX_API_KEY or not config.MINIMAX_GROUP_ID:
        die("请先在 web/.env 里配置 MINIMAX_API_KEY 和 MINIMAX_GROUP_ID（MiniMax 开放平台-账户管理里能找到）")

    voices_dir = os.path.join(config.BASE_DIR, "voices")
    audios = [
        f for f in sorted(glob.glob(os.path.join(voices_dir, "*")))
        if f.lower().endswith((".wav", ".mp3", ".m4a")) and not os.path.basename(f).startswith("_")
    ]
    if not audios:
        die(f"没找到录音。请把你的录音（wav/mp3/m4a，30秒~2分钟干净人声）放进 {voices_dir}")
    audio_path = audios[0]
    voice_id = sys.argv[1] if len(sys.argv) > 1 else "qunzong2026voice"
    print(f"素材: {os.path.basename(audio_path)}")
    print(f"voice_id: {voice_id}")

    base = config.MINIMAX_BASE_URL
    params = {"GroupId": config.MINIMAX_GROUP_ID}
    auth = {"Authorization": f"Bearer {config.MINIMAX_API_KEY}"}

    with httpx.Client(timeout=120) as c:
        print("1/3 上传音频…")
        with open(audio_path, "rb") as f:
            r = c.post(
                f"{base}/v1/files/upload", params=params, headers=auth,
                data={"purpose": "voice_clone"},
                files={"file": (os.path.basename(audio_path), f)},
            )
        print(f"    响应: {r.status_code} {r.text[:300]}")
        r.raise_for_status()
        file_id = (r.json().get("file") or {}).get("file_id")
        if not file_id:
            die("上传未返回 file_id，请检查上面的响应内容")

        print("2/3 发起克隆…")
        r = c.post(
            f"{base}/v1/voice_clone", params=params,
            headers={**auth, "Content-Type": "application/json"},
            json={
                "file_id": file_id,
                "voice_id": voice_id,
                "noise_reduction": True,
                "need_volume_normalization": True,
            },
        )
        print(f"    响应: {r.status_code} {r.text[:300]}")
        r.raise_for_status()

        print("3/3 用新音色合成试听…")
        r = c.post(
            f"{base}/v1/t2a_v2", params=params,
            headers={**auth, "Content-Type": "application/json"},
            json={
                "model": config.MINIMAX_TTS_MODEL,
                "text": TEST_TEXT,
                "stream": False,
                "voice_setting": {"voice_id": voice_id, "speed": config.MINIMAX_SPEED},
                "audio_setting": {"format": "mp3", "sample_rate": 24000, "channel": 1},
            },
        )
        r.raise_for_status()
        audio_hex = (r.json().get("data") or {}).get("audio")
        if not audio_hex:
            die(f"合成无音频返回: {r.text[:300]}")
        out = os.path.join(voices_dir, "_clone_test.mp3")
        with open(out, "wb") as f:
            f.write(bytes.fromhex(audio_hex))

    print()
    print(f"克隆完成！试听: {out}")
    print("满意的话，把下面两行更新到 web/.env 然后重启服务:")
    print(f"    TTS_PROVIDER=minimax")
    print(f"    MINIMAX_VOICE_ID={voice_id}")


if __name__ == "__main__":
    main()
