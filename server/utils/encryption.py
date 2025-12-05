"""
Encryption utilities for sensitive user data.
Uses Fernet (symmetric encryption) for encrypting sensitive fields like home address.
"""
import os
import base64
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
import logging

logger = logging.getLogger(__name__)

# Global encryption key (derived from JWT_SECRET for consistency)
_encryption_key = None
_fernet_instance = None


def get_encryption_key() -> bytes:
    """
    Get or generate encryption key from JWT_SECRET.
    Uses PBKDF2 to derive a stable key from JWT_SECRET.
    """
    global _encryption_key
    
    if _encryption_key is not None:
        return _encryption_key
    
    jwt_secret = os.getenv("JWT_SECRET")
    if not jwt_secret:
        raise ValueError("JWT_SECRET must be set for encryption")
    
    # Use PBKDF2 to derive a 32-byte key from JWT_SECRET
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=b'violetvibes_salt',  # Fixed salt (could be env var in production)
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(jwt_secret.encode()))
    _encryption_key = key
    
    return key


def get_fernet() -> Fernet:
    """Get or create Fernet instance for encryption/decryption."""
    global _fernet_instance
    
    if _fernet_instance is not None:
        return _fernet_instance
    
    key = get_encryption_key()
    _fernet_instance = Fernet(key)
    
    return _fernet_instance


def encrypt_data(data: str) -> str:
    """
    Encrypt sensitive data (e.g., home address).
    
    Args:
        data: Plain text string to encrypt
        
    Returns:
        Encrypted string (base64 encoded)
    """
    if not data:
        return ""
    
    try:
        fernet = get_fernet()
        encrypted = fernet.encrypt(data.encode())
        return encrypted.decode()
    except Exception as e:
        logger.error(f"Encryption error: {e}")
        raise ValueError(f"Failed to encrypt data: {e}")


def decrypt_data(encrypted_data: str) -> str:
    """
    Decrypt sensitive data (e.g., home address).
    
    Args:
        encrypted_data: Encrypted string (base64 encoded)
        
    Returns:
        Decrypted plain text string
    """
    if not encrypted_data:
        return ""
    
    try:
        fernet = get_fernet()
        decrypted = fernet.decrypt(encrypted_data.encode())
        return decrypted.decode()
    except Exception as e:
        logger.error(f"Decryption error: {e}")
        raise ValueError(f"Failed to decrypt data: {e}")
