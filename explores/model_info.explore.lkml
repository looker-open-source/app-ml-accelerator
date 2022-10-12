# Purpose of Explore: Explore Model List View, which will display all created models and relevant metadata.

include: "/views/model_info.view.lkml"

explore: model_info {
  hidden: yes
  persist_for: "0 minutes"
}
