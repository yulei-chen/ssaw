export interface Profile {
  id: string
  email: string
  display_name: string | null
  avatar_url: string | null
  partner_email: string | null
}

export interface TimeBlock {
  id: string
  user_id: string
  day: string
  start_time: string
  end_time: string
  created_at: string
}

/** Supabase returns block_notes as object for 1:1 relation, or array for 1:many */
export interface TimeBlockWithNote extends TimeBlock {
  block_notes?:
    | (BlockNote & { block_note_attachments?: { file_path: string }[] })[]
    | (BlockNote & { block_note_attachments?: { file_path: string }[] })
}

export interface BlockNote {
  id: string
  time_block_id: string
  content: string
  created_at: string
}

export interface BlockNoteAttachment {
  id: string
  block_note_id: string
  file_path: string
}

export interface Comment {
  id: string
  block_note_id: string
  user_id: string
  body: string
  created_at: string
}
