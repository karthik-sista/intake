export const SAVE_RELATIONSHIP = 'SAVE_RELATIONSHIP'
export const saveRelationship = ({screening_relationships: {id,
  client_id,
  relative_id,
  relationship_type,
  absent_parent_indicator,
  same_home_status}}) => ({
  type: SAVE_RELATIONSHIP,
  payload: {screening_relationships: id,
    client_id,
    relative_id,
    relationship_type,
    absent_parent_indicator,
    same_home_status},
})
