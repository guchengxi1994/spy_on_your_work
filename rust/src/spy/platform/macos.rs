use crate::spy::model::Application;
use crate::spy::model::ApplicationProvider;

impl ApplicationProvider for Application {
    fn from_process<T>(p: T) -> Option<Application> {
        todo!()
    }
}
