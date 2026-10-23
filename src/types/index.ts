export interface User {
  id: string;
  email: string;
  name?: string;
}

export interface Payment {
  id: string;
  person_id: string;
  amount: number;
  paid_on: string;
  note?: string | null;
  created_at: string;
}

export interface Comment {
  id: string;
  person_id: string;
  author_id: string;
  who?: string;
  author_name?: string;
  body: string;
  created_at: string;
  at?: string;
}

export interface Person {
  id: string;
  record_id: string;
  name: string;
  phone?: string | null;
  user_id?: string | null;
  created_at: string;
  payments?: Payment[];
}

export interface RecordItem {
  id: string;
  owner_id?: string;
  title: string;
  target?: number | null;
  end_date?: string | null;
  show_table: boolean;
  group_link: boolean;
  created_at: string;
  people: Person[];
}

export interface PersonViewData {
  name: string;
  title: string;
  target: number | null;
  show_table: boolean;
  claimed: boolean;
  me: boolean;
  payments: Array<{
    amount: number;
    paid_on: string;
    note?: string | null;
  }>;
  comments: Array<{
    who: string;
    body: string;
    at: string;
  }>;
  table?: Array<{
    id?: string;
    name: string;
    paid: number;
  }>;
}

export interface GroupViewData {
  title: string;
  people: Array<{
    id: string;
    name: string;
  }>;
}
