use std::io::*;
pub mod liner {
    pub struct Line {
        pub no: i32,
        pub content: String,
    }
    impl Line {
        #[derive(Debug)]
        pub fn new() -> Line {
            // This is body of the function.
            Line {
                no: 0,
                content: "".to_string(),
            }
        }
        pub fn as_tuple(self) -> (i32, String) {
            (self.no, self.content)
        }
    }
    enum LineType {
        Normal,
        Strange,
    }
}
mod other_mod {}
