import os
import torch
import numpy as np

from utils.util import load_config
from models.tts.fastspeech2.fs2 import FastSpeech2
from models.vocoders.gan.generator.hifigan import HiFiGAN
from processors.phone_extractor import phoneExtractor
from text.text_token_collation import phoneIDCollation


# Project paths
PROJECT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
AMPHION_DIR = os.path.join(PROJECT_DIR, "local_Amphion")

FASTSPEECH2_DIR = os.path.join(PROJECT_DIR, "local_models", "fastspeech2_ljspeech")
HIFIGAN_DIR = os.path.join(PROJECT_DIR, "local_models", "hifigan_inference")

FASTSPEECH2_CHECKPOINT = os.path.join(
    FASTSPEECH2_DIR,
    "checkpoint",
    "epoch-0125_step-0097902_loss-1.074404",
    "pytorch_model.bin",
)

HIFIGAN_CHECKPOINT = os.path.join(
    HIFIGAN_DIR,
    "step-0560000_loss-51.2373.pt",
)


# Select the best available device
DEVICE = torch.device(
    "mps" if torch.backends.mps.is_available()
    else "cpu"
)


def load_model_config(config_path):
    """Load an Amphion model configuration."""
    os.environ["WORK_DIR"] = AMPHION_DIR
    cfg = load_config(config_path)
    return cfg


def prepare_fastspeech2_config():
    """Prepare FastSpeech 2 configuration for local inference."""
    config_path = os.path.join(FASTSPEECH2_DIR, "args.json")
    cfg = load_model_config(config_path)

    cfg.preprocess.lexicon_path = os.path.join(
        AMPHION_DIR, cfg.preprocess.lexicon_path
    )

    cfg.preprocess.processed_dir = FASTSPEECH2_DIR

    return cfg


def prepare_hifigan_config():
    """Prepare HiFi-GAN configuration for local inference."""
    config_path = os.path.join(HIFIGAN_DIR, "args.json")
    cfg = load_model_config(config_path)
    return cfg


def load_fastspeech2():
    """Load the trained FastSpeech 2 model."""
    cfg = prepare_fastspeech2_config()

    model = FastSpeech2(cfg)

    state_dict = torch.load(
        FASTSPEECH2_CHECKPOINT,
        map_location="cpu",
        weights_only=False,
    )

    model.load_state_dict(state_dict, strict=True)

    model = model.to(DEVICE)
    model.eval()

    print("FastSpeech 2 model loaded successfully!")
    print("Device:", DEVICE)

    return model, cfg


def load_hifigan():
    """Load the trained HiFi-GAN generator."""
    cfg = prepare_hifigan_config()

    model = HiFiGAN(cfg)

    checkpoint = torch.load(
        HIFIGAN_CHECKPOINT,
        map_location="cpu",
        weights_only=False,
    )

    model.load_state_dict(
        checkpoint["generator_state_dict"],
        strict=True,
    )

    model = model.to(DEVICE)
    model.eval()

    print("HiFi-GAN model loaded successfully!")
    print("Device:", DEVICE)

    return model, cfg


def convert_text_to_phone_ids(text, cfg):
    """Convert English text into FastSpeech 2 phone IDs."""
    phone_extractor = phoneExtractor(cfg)
    phone_sequence = phone_extractor.extract_phone(text)

    phone_sequence = ["{"] + phone_sequence + ["}"]

    phone_collator = phoneIDCollation(
        cfg, symbols_dict_file=None
    )

    phone_ids = phone_collator.get_phone_id_sequence(
        cfg, phone_sequence
    )

    return torch.tensor(phone_ids, dtype=torch.long)


def generate_mel_spectrogram(model, phone_ids):
    """Generate a mel-spectrogram using FastSpeech 2."""
    phone_ids = phone_ids.to(DEVICE)

    input_data = {
        "texts": phone_ids.unsqueeze(0),
        "text_len": torch.tensor(
            [phone_ids.size(0)], dtype=torch.long, device=DEVICE
        ),
        "spk_id": torch.tensor([0], dtype=torch.long, device=DEVICE),
    }

    with torch.no_grad():
        output = model(
            input_data,
            p_control=1.0,
            e_control=1.0,
            d_control=1.0,
        )

    mel_length = int(output["mel_lens"][0].item())

    mel = output["postnet_output"][0, :mel_length, :]

    mel = mel.transpose(0, 1).unsqueeze(0)

    print("Mel-spectrogram generated successfully!")
    print("Mel shape:", tuple(mel.shape))

    return mel


def generate_audio(model, mel, cfg):
    """Convert a mel-spectrogram into audio using HiFi-GAN."""
    mel = mel.to(DEVICE)

    with torch.no_grad():
        audio = model(mel)

    audio = audio.squeeze().detach().cpu().numpy()

    sample_rate = cfg.preprocess.sample_rate

    print("Audio waveform generated successfully!")
    print("Audio samples:", len(audio))
    print("Sample rate:", sample_rate)
    print("Duration:", round(len(audio) / sample_rate, 2), "seconds")

    return audio, sample_rate


def save_audio(audio, sample_rate, output_path):
    """Save generated speech as a WAV file."""
    import soundfile as sf

    sf.write(output_path, audio, sample_rate)

    print("Audio saved successfully!")
    print("File:", output_path)


def generate_speech(text, output_path="generated_speech_local.wav"):
    """Generate speech locally using FastSpeech 2 and HiFi-GAN."""
    if not text or not text.strip():
        raise ValueError("Input text cannot be empty.")

    fs2_model, fs2_cfg = load_fastspeech2()

    phone_ids = convert_text_to_phone_ids(text, fs2_cfg)

    mel = generate_mel_spectrogram(fs2_model, phone_ids)

    vocoder_model, vocoder_cfg = load_hifigan()

    audio, sample_rate = generate_audio(
        vocoder_model, mel, vocoder_cfg
    )

    save_audio(audio, sample_rate, output_path)

    return output_path
