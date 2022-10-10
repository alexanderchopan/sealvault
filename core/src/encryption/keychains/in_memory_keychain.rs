// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.

use std::{
    collections::HashMap,
    fmt::{Debug, Formatter},
    sync::{Arc, RwLock},
};

use crate::{
    encryption::{
        key_material::KeyMaterial,
        keychains::keychain::{soft_delete_rename, KeychainImpl},
        KeyEncryptionKey,
    },
    Error,
};

/// In-memory keychain for testing.
pub(super) struct InMemoryKeychain {
    data: Arc<RwLock<HashMap<String, KeyMaterial>>>,
}

impl InMemoryKeychain {
    pub fn new() -> Self {
        let data = Arc::new(RwLock::new(HashMap::new()));
        InMemoryKeychain { data }
    }
}

impl KeychainImpl for InMemoryKeychain {
    fn get(&self, name: &str) -> Result<KeyEncryptionKey, Error> {
        let d = self.data.read()?;
        // Only case when we want to use the `clone_for_in_memory_keychain` method.
        #[allow(deprecated)]
        let key_material = d
            .get(name)
            .map(|s| (*s).clone_for_in_memory_keychain().expect("valid key"))
            .ok_or_else(|| Error::Fatal {
                error: format!("Key '{}' not found", name),
            })?;
        Ok(KeyEncryptionKey::new(name.into(), key_material))
    }

    fn soft_delete(&self, name: &str) -> Result<(), Error> {
        let key = self.get(name)?;
        let new_name = soft_delete_rename(name);
        let (_, key_material) = key.into_keychain();
        let key = KeyEncryptionKey::new(new_name, key_material);
        self.put_local_unlocked(key)?;

        let mut d = self.data.write()?;
        let _ = d.remove(name);

        Ok(())
    }

    fn put_local_unlocked(&self, key: KeyEncryptionKey) -> Result<(), Error> {
        use std::collections::hash_map::Entry;
        let mut d = self.data.write()?;
        let (name, key_material) = key.into_keychain();
        if let Entry::Vacant(e) = d.entry(name) {
            e.insert(key_material);
            Ok(())
        } else {
            Err(Error::Fatal {
                error: "A keychain item by this name already exists".into(),
            })
        }
    }
}

impl Debug for InMemoryKeychain {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("InMemoryKeychain").finish()
    }
}
