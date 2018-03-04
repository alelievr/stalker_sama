/\|/ {
  split($0, col_name, "|");
  column_names[++n] = col_name[2];
}
/INSERT INTO \"[A-Za-z].*\"/ {
  insert_part = match($0, /INSERT INTO \"[A-Za-z].*\"/);
  printf("%s ", substr($0, RSTART, RLENGTH));

  printf("(");
  for (i = 1; i <= n; i++) {
    if (i == 1) {
      printf("%s", column_names[i]);
    }
    else {
      printf(", %s", column_names[i]);
    }
  }
  printf(") ");

  values_part = substr($0, RLENGTH+1, length($0) - RSTART);
  printf("%s\n", values_part);


}

